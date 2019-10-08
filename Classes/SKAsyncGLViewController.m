//
//  SKAntialiasedAsyncGLViewController.m
//  SKAsyncGLViewController
//
//  Created by Stephen Kopylov - Home on 28/04/16.
//  Copyright © 2016 Admin. All rights reserved.
//

#import "SKAsyncGLViewController.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

@interface SKAsyncGLViewController ()
@property (atomic) GLuint renderbuffer;
@property (nonatomic) CGRect savedRect;
@end

@implementation SKAsyncGLViewController

#pragma mark - public methods

- (void)drawGLInRect:(CGRect)rect
{
    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}


#pragma mark - private methods

- (void)updateBuffersSize:(CGRect)rect
{
    if ( CGRectEqualToRect(rect, _savedRect)) {
        return;
    }
    
    _savedRect = rect;
    
    CGFloat width = rect.size.width;
    CGFloat height = rect.size.height;
    
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8_OES, width, height);
}


#pragma mark - SKAsyncGLViewControllerDelegate

- (void)setupGL:(CGRect)rect
{
    glGenRenderbuffers(1, &_renderbuffer);
    
    [self updateBuffersSize:CGRectMake(0.0f, 0.0f, rect.size.width *[UIScreen mainScreen].scale, rect.size.height *[UIScreen mainScreen].scale)];
    
    glBindFramebuffer(GL_FRAMEBUFFER, self.view.framebuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _renderbuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT, GL_RENDERBUFFER, _renderbuffer);
}


- (void)drawGL:(CGRect)rect
{
    [self updateBuffersSize:rect];
    
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    
    [self drawGLInRect:rect];
    
    glFlush();
}


- (void)clearGL
{
    [super clearGL];
    
    if ( _renderbuffer != 0 ) {
        glDeleteRenderbuffers(1, &_renderbuffer);
        _renderbuffer =  0;
    }
}


@end
