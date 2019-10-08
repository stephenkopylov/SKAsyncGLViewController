//
//  SKAsyncGLViewController.m
//  SKAsyncGLViewController
//
//  Created by Stephen Kopylov - Home on 27/04/16.
//  Copyright © 2016 test. All rights reserved.
//

#import "SKBaseAsyncGLViewController.h"
#import "RDRIntermediateTarget.h"

@interface SKBaseAsyncGLViewController ()
@end

@implementation SKBaseAsyncGLViewController

@dynamic view;

#pragma mark - lifecycle

- (void)loadView
{
    self.api = [self getApi];
    
    self.view = [SKAsyncGLView new];
    self.view.delegate = self;
}


- (void)dealloc
{
    if ( self.displayLink ) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
    
    dispatch_sync(self.view.renderQueue, ^{
        [EAGLContext setCurrentContext:self.view.renderContext];
        
        glFlush();
        
        [self clearGL];
        
        [self.view clear];
    });
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if ( self.displayLink ) {
        self.displayLink.paused = YES;
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    if ( self.displayLink ) {
        self.displayLink.paused = self.paused;
    }
}


- (void)removeFromParentViewController
{
    [super removeFromParentViewController];
    
    if ( self.displayLink ) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}


#pragma mark - private methods

- (void)render
{
    [self.view render];
}


#pragma mark - getters/setters

- (void)setPaused:(BOOL)paused
{
    _paused = paused;
    
    self.displayLink.paused = _paused;
}


#pragma mark - SKAsyncGLViewDelegate

-(void)createBuffers:(CGRect)rect
{
    [self setupGL:rect];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        RDRIntermediateTarget *target = [RDRIntermediateTarget intermediateTargetWithTarget:self];
        self.displayLink = [CADisplayLink displayLinkWithTarget:target selector:@selector(render)];
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    });
}


- (void)drawInRect:(CGRect)rect
{
    [self drawGL:rect];
}

-(EAGLRenderingAPI)getApi{
    return kEAGLRenderingAPIOpenGLES3;
}

- (void)setupGL:(CGRect)rect
{
    //    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}


- (void)drawGL:(CGRect)rect
{
    //    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}


- (void)clearGL
{
    //    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}


@end
