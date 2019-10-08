//
//  SKAsyncGLViewController.h
//  SKAsyncGLViewController
//
//  Created by Stephen Kopylov - Home on 27/04/16.
//  Copyright © 2016 test. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SKAsyncGLView.h"

@class SKBaseAsyncGLViewController;

@interface SKBaseAsyncGLViewController : UIViewController<SKAsyncGLViewDelegate>

@property (strong, nonatomic) SKAsyncGLView *view;

@property (nonatomic) CADisplayLink *displayLink;

@property (nonatomic) BOOL paused;

@property (nonatomic) EAGLRenderingAPI api;

- (void)setupGL:(CGRect)rect;

- (void)drawGL:(CGRect)rect;

- (void)clearGL;

@end
