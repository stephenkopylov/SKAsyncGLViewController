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

@protocol SKAsyncGLViewControllerDelegate <NSObject>

- (void)setupGL:(SKAsyncGLViewController *)viewController;

- (void)drawGL:(CGRect)rect;

- (void)clearGL:(SKAsyncGLViewController *)viewController;

@end

@interface SKAsyncGLViewController : UIViewController<SKAsyncGLViewDelegate, SKAsyncGLViewControllerDelegate>

@property (strong, nonatomic) SKAsyncGLView *view;

@property (nonatomic) CADisplayLink *displayLink;

@property (nonatomic) BOOL paused;

@property (nonatomic, weak) id<SKAsyncGLViewControllerDelegate> delegate;

@end