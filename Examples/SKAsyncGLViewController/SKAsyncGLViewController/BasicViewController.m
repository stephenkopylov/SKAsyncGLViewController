//
//  BasicViewController.m
//  SKAsyncGLViewController
//
//  Created by Stephen Kopylov - Home on 28/04/16.
//  Copyright © 2016 test. All rights reserved.
//

#import "BasicViewController.h"

@interface BasicViewController ()

@end

@implementation BasicViewController

#pragma mark - SKAsyncGLViewControllerDelegate

- (void)drawInRect:(CGRect)rect
{
    glClearColor(1.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glFlush();
}


@end
