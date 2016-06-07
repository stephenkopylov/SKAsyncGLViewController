//
//  SKAsyncGLView.m
//  SKAsyncGLViewController
//
//  Created by Stephen Kopylov - Home on 27/04/16.
//  Copyright © 2016 test. All rights reserved.
//

#import "SKAsyncGLView.h"

@interface SKAsyncGLView ()
@property (nonatomic) BOOL contextsCreated;
@property (nonatomic) BOOL buffersCreated;
@property (atomic) BOOL rendering;
@property (atomic) BOOL inactive;
@end

@implementation SKAsyncGLView

+ (Class)layerClass
{
    return [CAEAGLLayer class];
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
        ((CAEAGLLayer *)self.layer).contentsScale = [UIScreen mainScreen].scale;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActiveNotification) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForegroundNotification) name:UIApplicationWillEnterForegroundNotification object:nil];
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


- (void)removeFromSuperview
{
    [super removeFromSuperview];
    
    _inactive = YES;
    
    dispatch_async(self.renderQueue, ^{
        [EAGLContext setCurrentContext:self.renderContext];
        
        if ( _framebuffer != 0 ) {
            glDeleteFramebuffers(1, &_framebuffer);
            _framebuffer =  0;
        }
        
        if ( [_delegate respondsToSelector:@selector(removeBuffersForView:)] ) {
            [_delegate removeBuffersForView:self];
        }
        
        _renderContext = nil;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [EAGLContext setCurrentContext:self.mainContext];
            
            if ( _renderbuffer != 0 ) {
                glDeleteRenderbuffers(1, &_renderbuffer);
                _renderbuffer =  0;
            }
            
            _mainContext = nil;
        });
    });
}


- (void)applicationWillResignActiveNotification
{
    _inactive = YES;
}


- (void)applicationWillEnterForegroundNotification
{
    _inactive = NO;
}


#pragma mark - private methods

- (void)createContexts
{
    self.mainContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    dispatch_async(self.renderQueue, ^{
        self.renderContext = [[EAGLContext alloc] initWithAPI:self.mainContext.API sharegroup:self.mainContext.sharegroup];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self createBuffers];
        });
    });
}


- (void)createBuffers
{
    [EAGLContext setCurrentContext:self.mainContext];
    
    glGenRenderbuffers(1, &_renderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    
    [self.mainContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    
    _buffersCreated = YES;
    
    dispatch_async(self.renderQueue, ^{
        [EAGLContext setCurrentContext:self.renderContext];
        
        glGenFramebuffers(1, &_framebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _framebuffer);
        
        if ( [_delegate respondsToSelector:@selector(createBuffersForView:)] ) {
            [_delegate createBuffersForView:self];
        }
        
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        
        if ( _log ) {
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
    if ( [self isRenderable] && !_rendering ) {
        CGFloat width = self.frame.size.width * [UIScreen mainScreen].scale;
        CGFloat height = self.frame.size.height *  [UIScreen mainScreen].scale;
        
        dispatch_async(self.renderQueue, ^{
            if ( [self isRenderable] && !_rendering ) {
                _rendering = YES;
                
                [EAGLContext setCurrentContext:self.renderContext];
                
                glViewport(0, 0, width, height);
                glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
                
                CGRect rect = CGRectMake(0, 0, width, height);
                
                if ( [_delegate respondsToSelector:@selector(drawInRect:)] ) {
                    [_delegate drawInRect:rect];
                }
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    if ( [self isRenderable] ) {
                        [EAGLContext setCurrentContext:self.mainContext];
                        glBindFramebuffer(GL_FRAMEBUFFER, _renderbuffer);
                        glViewport(0, 0, width, height);
                        
                        [self.mainContext presentRenderbuffer:_renderbuffer];
                        glFlush();
                    }
                });
                
                _rendering = NO;
            }
        });
    }
}


- (BOOL)isRenderable
{
    if ( _inactive || self.frame.size.width == 0.0f || self.frame.size.height == 0.0f || self.isHidden || [UIApplication sharedApplication].applicationState != UIApplicationStateActive || !self.superview || self.layer.frame.size.width == 0.0f || self.layer.frame.size.height == 0.0f ) {
        return NO;
    }
    
    return YES;
}


@end
