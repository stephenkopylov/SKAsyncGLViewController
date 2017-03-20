//
//  AntialiasedAsyncGLViewController.m
//  ExpertOption
//
//  Created by Stephen Kopylov - Home on 28/04/16.
//  Copyright © 2016 Admin. All rights reserved.
//

#import "SKAntialiasedAsyncGLViewController.h"
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/ES2/gl.h>

@interface SKAntialiasedAsyncGLViewController ()
@property (nonatomic) GLuint stencilbuffer;
@property (nonatomic) GLuint sampleframebuffer;
@property (nonatomic) GLuint samplestencilbuffer;
@property (nonatomic) GLuint samplerenderbuffer;

@property (nonatomic) CGRect savedRect;
@end

@implementation SKAntialiasedAsyncGLViewController

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
    
    glBindRenderbuffer(GL_RENDERBUFFER, _stencilbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8_OES, width, height);
    
    GLint samples;
    glGetIntegerv(GL_MAX_SAMPLES_APPLE, &samples);
    
    glBindRenderbuffer(GL_RENDERBUFFER, _samplerenderbuffer);
    glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, samples, GL_RGBA8_OES, width, height);
    
    glBindRenderbuffer(GL_RENDERBUFFER, _samplestencilbuffer);
    glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, samples, GL_DEPTH24_STENCIL8_OES, width, height);
}


#pragma mark - SKAsyncGLViewControllerDelegate

- (void)setupGL:(SKAsyncGLViewController *)viewController
{
    glGenRenderbuffers(1, &_stencilbuffer);
    
    glGenRenderbuffers(1, &_samplerenderbuffer);
    glGenRenderbuffers(1, &_samplestencilbuffer);
    
    [self updateBuffersSize:CGRectMake(0.0f, 0.0f, self.view.frame.size.width *[UIScreen mainScreen].scale, self.view.frame.size.height *[UIScreen mainScreen].scale)];
    
    glGenFramebuffers(1, &_sampleframebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _sampleframebuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _samplerenderbuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _samplestencilbuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT, GL_RENDERBUFFER, _samplestencilbuffer);
}


- (void)drawGL:(CGRect)rect
{
    [self updateBuffersSize:rect];
    
    glBindRenderbuffer(GL_RENDERBUFFER, _samplestencilbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _samplerenderbuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _sampleframebuffer);
    
    glClearColor(0.f, 0.f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
    
    if ( ![self.view isRenderable] ) {
        return;
    }
    
    [self drawGLInRect:rect];
    
    if ( ![self.view isRenderable] ) {
        return;
    }
    
    GLenum err = glGetError();
    if (err != GL_NO_ERROR) {
        return;
    }
    
    glBindFramebuffer(GL_READ_FRAMEBUFFER_APPLE, _sampleframebuffer);
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER_APPLE, self.view.framebuffer);
    @try {
        glResolveMultisampleFramebufferAPPLE();
        
        const GLenum discards[]  = { GL_COLOR_ATTACHMENT0, GL_DEPTH_ATTACHMENT };
        glDiscardFramebufferEXT(GL_READ_FRAMEBUFFER_APPLE, 2, discards);
        
        if ( ![self.view isRenderable] ) {
            return;
        }
        
        glFlush();
    } @catch ( NSException *ex ) {
    }
}


- (void)clearGL:(SKAsyncGLViewController *)viewController
{
    if ( _stencilbuffer != 0 ) {
        glDeleteRenderbuffers(1, &_stencilbuffer);
        _stencilbuffer =  0;
    }
    
    if ( _sampleframebuffer != 0 ) {
        glDeleteFramebuffers(1, &_sampleframebuffer);
        _sampleframebuffer =  0;
    }
    
    if ( _samplestencilbuffer != 0 ) {
        glDeleteRenderbuffers(1, &_samplestencilbuffer);
        _samplestencilbuffer =  0;
    }
    
    if ( _samplerenderbuffer != 0 ) {
        glDeleteRenderbuffers(1, &_samplerenderbuffer);
        _samplerenderbuffer =  0;
    }
}


@end
