//
//  SKAsyncGLView.m
//  SKAsyncGLViewController
//
//  Created by Stephen Kopylov - Home on 27/04/16.
//  Copyright © 2016 test. All rights reserved.
//

#import "SKAsyncGLView.h"
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

@interface SKAsyncGLView ()
@property (nonatomic) BOOL contextsCreated;
@property (nonatomic) BOOL buffersCreated;
@property (atomic) BOOL rendering;
@property (atomic) BOOL isRenderable;
@property (nonatomic) CGFloat contentScale;
@end

static NSMutableDictionary<NSString*, EAGLSharegroup*> * sharedGroups;

@implementation SKAsyncGLView

+ (Class)layerClass
{
	return [CAEAGLLayer class];
}

+(void)load{
	sharedGroups = @{}.mutableCopy;
}

#pragma mark - lifecycle/ui


- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (instancetype)init
{
	self = [super init];
	
	if ( self ) {
		_contextsCreated = NO;
		_buffersCreated = NO;
		
		self.renderQueue = dispatch_queue_create("Render-Queue", DISPATCH_QUEUE_SERIAL);
		
		((CAEAGLLayer *)self.layer).opaque = NO;
		self.fullResolutionOnSimulator = false;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActiveNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActiveNotification:) name:UIApplicationWillTerminateNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForegroundNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
	}
	
	return self;
}


- (void)layoutSubviews
{
	[super layoutSubviews];
	
	if ( !_contextsCreated ) {
		_contextsCreated = YES;
		[self createContexts];
	}
	
	if ( _buffersCreated ) {
		[self.mainContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
	}
}


- (void)applicationWillResignActiveNotification:(NSNotification *)notification
{
	self.inactive = YES;
	[EAGLContext setCurrentContext:self.mainContext];
	glFlush();
	
	dispatch_sync(self.renderQueue, ^{
		[EAGLContext setCurrentContext:self.renderContext];
		glFlush();
	});
}


- (void)applicationWillEnterForegroundNotification:(NSNotification *)notification
{
	@synchronized(self) {
		self.inactive = NO;
	}
}


#pragma mark - private methods

- (void)createContexts
{
	
	if(self.useSharedContextInSameThread){
		
		NSString *renderQueueID =  [NSString stringWithUTF8String:dispatch_queue_get_label(self.renderQueue)];
		
		if(sharedGroups[renderQueueID]){
			self.mainContext = [[EAGLContext alloc] initWithAPI:[self.delegate getApi] sharegroup:sharedGroups[renderQueueID]];
		}else{
			self.mainContext = [[EAGLContext alloc] initWithAPI:[self.delegate getApi]];
			sharedGroups[renderQueueID] = self.mainContext.sharegroup;
		}
	}else{
		self.mainContext = [[EAGLContext alloc] initWithAPI:[self.delegate getApi]];
	}
	
	dispatch_async(self.renderQueue, ^{
		self.renderContext = [[EAGLContext alloc] initWithAPI:self.mainContext.API sharegroup:self.mainContext.sharegroup];
		dispatch_async(dispatch_get_main_queue(), ^{
			[self createBuffers];
		});
	});
}

- (void)createBuffers
{
	CGRect rect = self.frame;
	
	[EAGLContext setCurrentContext:self.mainContext];
	
	glGenRenderbuffers(1, &_renderbuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
	
	[self.mainContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
	
	_buffersCreated = YES;
	
	__typeof__(self) __weak wself = self;
	
	dispatch_async(self.renderQueue, ^{
		__typeof__(wself) __strong sself = wself;
		
		[EAGLContext setCurrentContext:sself.renderContext];
		
		GLuint framebuffer ;
		glGenFramebuffers(1, &framebuffer);
		glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, framebuffer);
		
		sself.framebuffer = framebuffer;
		
		if ( [sself.delegate respondsToSelector:@selector(createBuffers:)] ) {
			[sself.delegate createBuffers:rect];
		}
		
		GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
		
		if ( sself.log ) {
			if ( status == GL_FRAMEBUFFER_COMPLETE ) {
				NSLog(@"framebuffer complete");
			}
			else if ( status == GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT ) {
				NSLog(@"incomplete framebuffer attachments");
			}
			else if ( status == GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT ) {
				NSLog(@"incomplete missing framebuffer attachments");
			}
			else if ( status == GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS ) {
				NSLog(@"incomplete framebuffer attachments dimensions");
			}
			else if ( status == GL_FRAMEBUFFER_UNSUPPORTED ) {
				NSLog(@"combination of internal formats used by attachments in thef ramebuffer results in a nonrednerable target");
			}
		}
	});
}


- (void)render
{
	self.isRenderable = !self.inactive && self.frame.size.width > 0.0f && self.frame.size.height > 0.0f && !self.isHidden && [UIApplication sharedApplication].applicationState != UIApplicationStateBackground && self.superview && self.layer.frame.size.width > 0.0f && self.layer.frame.size.height > 0.0f;
	
	if ( self.isRenderable && !self.rendering ) {
		CGFloat width = self.frame.size.width * _contentScale;
		CGFloat height = self.frame.size.height *  _contentScale;
		
		__typeof__(self) __weak wself = self;
		dispatch_async(self.renderQueue, ^{
			
			__typeof__(wself) __strong sself = wself;
			if ( sself.isRenderable && !sself.rendering ) {
				sself.rendering = YES;
				
				[EAGLContext setCurrentContext:sself.renderContext];
				
				glViewport(0, 0, width, height);
				glBindFramebuffer(GL_FRAMEBUFFER, sself.framebuffer);
				
				CGRect rect = CGRectMake(0, 0, width, height);
				
				if ( [sself.delegate respondsToSelector:@selector(drawInRect:)] ) {
					[sself.delegate drawInRect:rect];
				}
				
				glFlush();
				
				dispatch_async(dispatch_get_main_queue(), ^{
					if ( sself.isRenderable ) {
						[EAGLContext setCurrentContext:sself.mainContext];
						glBindRenderbuffer(GL_RENDERBUFFER, sself.renderbuffer);
						glViewport(0, 0, width, height);
						
						[sself.mainContext presentRenderbuffer:sself.renderbuffer];
						glFlush();
					}
					
					sself.rendering = NO;
				});
			}
		});
	}
}


- (void)clear
{
	self.inactive = YES;
	
	if ( _framebuffer != 0 ) {
		glDeleteFramebuffers(1, &_framebuffer);
		_framebuffer =  0;
	}
	
	_renderContext = nil;
	
	[EAGLContext setCurrentContext:self.mainContext];
	
	if ( _renderbuffer != 0 ) {
		glDeleteRenderbuffers(1, &_renderbuffer);
		_renderbuffer =  0;
	}
	
	_mainContext = nil;
}


-(void)setContentScale:(CGFloat)contentScale{
	_contentScale = contentScale;
	
	((CAEAGLLayer *)self.layer).contentsScale = _contentScale;
}

#pragma mark - public methods

- (void)setDelegate:(id<SKAsyncGLViewDelegate>)delegate
{
	_delegate = delegate;
}

-(void)setFullResolutionOnSimulator:(BOOL)fullResolutionOnSimulator
{
	_fullResolutionOnSimulator = fullResolutionOnSimulator;
	
#if TARGET_IPHONE_SIMULATOR
	self.contentScale = _fullResolutionOnSimulator ? [UIScreen mainScreen].scale : 1.f;
#else
	self.contentScale = [UIScreen mainScreen].scale;
#endif
}

@end
