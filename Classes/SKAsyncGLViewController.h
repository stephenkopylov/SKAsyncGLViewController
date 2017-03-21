//
//  SKAsyncGLViewController.h
//  SKAsyncGLViewController
//
//  Created by Stephen Kopylov - Home on 27/04/16.
//  Copyright © 2016 test. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SKAsyncGLView.h"

@class SKAsyncGLViewController;

@interface SKAsyncGLViewController : UIViewController<SKAsyncGLViewDelegate>

@property (strong, nonatomic) SKAsyncGLView *view;

@property (nonatomic) CADisplayLink *displayLink;

@property (nonatomic) BOOL paused;


- (void)setupGL;


- (void)drawGL:(CGRect)rect;


- (void)clearGL;

@end
