//
//  SKAsyncGLViewController.m
//  SKAsyncGLViewController
//
//  Created by Stephen Kopylov - Home on 27/04/16.
//  Copyright © 2016 test. All rights reserved.
//

#import "SKAsyncGLViewController.h"
#import "RDRIntermediateTarget.h"

@interface SKAsyncGLViewController ()
@end

@implementation SKAsyncGLViewController

@dynamic view;

#pragma mark - lifecycle

- (void)loadView
{
    self.delegate = self;
    self.view = [SKAsyncGLView new];
    self.view.delegate = self;
}


- (void)dealloc
{
    if ( self.displayLink ) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
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


- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    if(!self.view.inactive){
        @synchronized (self) {
            self.view.inactive = YES;
            
            __weak typeof(self) weakSelf = self;
            [coordinator animateAlongsideTransition:^(id < UIViewControllerTransitionCoordinatorContext > context) {
            } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
                typeof(weakSelf) strongSelf = weakSelf;
                dispatch_async(dispatch_get_main_queue(), ^{
                    strongSelf.view.inactive = NO;
                });
            }];
        }
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

- (void)createBuffersForView:(SKAsyncGLView *)asyncView
{
    if ( [_delegate respondsToSelector:@selector(setupGL:)] ) {
        [_delegate setupGL:self];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        RDRIntermediateTarget *target = [RDRIntermediateTarget intermediateTargetWithTarget:self];
        self.displayLink = [CADisplayLink displayLinkWithTarget:target selector:@selector(render)];
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    });
}


- (void)removeBuffersForView:(SKAsyncGLView *)asyncView
{
    if ( [_delegate respondsToSelector:@selector(clearGL:)] ) {
        [_delegate clearGL:self];
    }
}


- (void)drawInRect:(CGRect)rect
{
    if ( [_delegate respondsToSelector:@selector(drawGL:)] ) {
        [_delegate drawGL:rect];
    }
}


#pragma mark - SKAsyncGLViewControllerDelegate

- (void)setupGL:(SKAsyncGLViewController *)viewController
{
    //    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}


- (void)drawGL:(CGRect)rect
{
    //    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}


- (void)clearGL:(SKAsyncGLViewController *)viewController
{
    //    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}


@end
