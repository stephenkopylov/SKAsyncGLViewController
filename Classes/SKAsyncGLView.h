//
//  SKAsyncGLView.h
//  SKAsyncGLViewController
//
//  Created by Stephen Kopylov - Home on 27/04/16.
//  Copyright © 2016 test. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@class SKAsyncGLView;

@protocol SKAsyncGLViewDelegate <NSObject>

- (void)createBuffers:(CGRect)rect;

- (void)drawInRect:(CGRect)rect;

- (EAGLRenderingAPI)getApi;

@end

@interface SKAsyncGLView : UIView

@property (nonatomic, strong) dispatch_queue_t renderQueue;
@property (nonatomic) GLuint renderbuffer;
@property (nonatomic) GLuint framebuffer;
@property (nonatomic, strong) EAGLContext *mainContext;
@property (nonatomic, strong) EAGLContext *renderContext;
@property (nonatomic) BOOL log;
@property (atomic) BOOL inactive;
@property (nonatomic) BOOL fullResolutionOnSimulator;
@property (atomic) BOOL useSharedContextInSameThread;

@property (nonatomic, weak) id<SKAsyncGLViewDelegate> delegate;

- (void)render;
//- (BOOL)isRenderable;

- (void)clear;

@end
