//
//  ViewController.m
//  SKAsyncGLViewController
//
//  Created by Stephen Kopylov - Home on 27/04/16.
//  Copyright © 2016 test. All rights reserved.
//

#define boris_random(smallNumber, bigNumber) ((((float)(arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * (bigNumber - smallNumber)) + smallNumber)
#define SIDE 150.0f

#import "ViewController.h"
#import "CubeViewController.h"

@interface ViewController ()

@end

@implementation ViewController {
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
}


- (IBAction)buttonTapped:(id)sender
{
    CubeViewController *vc = [CubeViewController new];
    
    vc.floating = YES;
    [self addChildViewController:vc];
    [vc didMoveToParentViewController:self];
    
    vc.view.frame = CGRectMake(boris_random(0.0, self.view.frame.size.width - SIDE), boris_random(0.0, self.view.frame.size.height - SIDE), SIDE, SIDE);
    vc.view.alpha = 0.0f;
    [self.view addSubview:vc.view];
    
    [UIView animateWithDuration:0.2 animations:^{
        vc.view.alpha = 1.0f;
    }];
}


@end
