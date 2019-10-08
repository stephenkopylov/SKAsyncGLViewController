//
//  SKAntialiasedAsyncGLViewController.m
//  SKAsyncGLViewController
//
//  Created by Stephen Kopylov - Home on 28/04/16.
//  Copyright © 2016 Admin. All rights reserved.
//

#import "SKAntialiasedAsyncGLViewController.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

@interface SKAntialiasedAsyncGLViewController ()
@property (atomic) GLuint sampleframebuffer;
@property (atomic) GLuint samplestencilbuffer;
@property (atomic) GLuint samplerenderbuffer;

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
    
    
    GLint samples;
    glGetIntegerv(GL_MAX_SAMPLES_APPLE, &samples);
    
    glBindRenderbuffer(GL_RENDERBUFFER, _samplerenderbuffer);
    glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, samples, GL_RGBA8_OES, width, height);
    
    glBindRenderbuffer(GL_RENDERBUFFER, _samplestencilbuffer);
    glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, samples, GL_DEPTH24_STENCIL8_OES, width, height);
}


#pragma mark - SKAsyncGLViewControllerDelegate

-(void)setupGL:(CGRect)rect
{
    glGenRenderbuffers(1, &_samplerenderbuffer);
    glGenRenderbuffers(1, &_samplestencilbuffer);
    
    [self updateBuffersSize:CGRectMake(0.0f, 0.0f, rect.size.width *[UIScreen mainScreen].scale, rect.size.height *[UIScreen mainScreen].scale)];
    
    glGenFramebuffers(1, &_sampleframebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _sampleframebuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _samplerenderbuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _samplestencilbuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT, GL_RENDERBUFFER, _samplestencilbuffer);
}


- (void)drawGL:(CGRect)rect
{
    [self updateBuffersSize:rect];
    
    glBindFramebuffer(GL_FRAMEBUFFER, _sampleframebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _samplestencilbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _samplerenderbuffer);
    
    [self drawGLInRect:rect];
    
    glBindFramebuffer(GL_READ_FRAMEBUFFER_APPLE, _sampleframebuffer);
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER_APPLE, self.view.framebuffer);
    
    glFlush();
    
    if(self.api == kEAGLRenderingAPIOpenGLES2){
        glResolveMultisampleFramebufferAPPLE();
    }else{
        glBlitFramebuffer(0,0,rect.size.width,rect.size.height, 0,0,rect.size.width,rect.size.height, GL_COLOR_BUFFER_BIT, GL_NEAREST);
    }
    
    const GLenum discards[]  = { GL_COLOR_ATTACHMENT0, GL_DEPTH_ATTACHMENT };
    glDiscardFramebufferEXT(GL_READ_FRAMEBUFFER_APPLE, 2, discards);
}


- (void)clearGL
{
    [super clearGL];
    
    if ( _sampleframebuffer != 0 ) {
        glDeleteFramebuffers(1, &_sampleframebuffer);
        _sampleframebuffer =  0;
    }
    
    if ( _samplestencilbuffer != 0 ) {
        glDeleteFramebuffers(1, &_samplestencilbuffer);
        _samplestencilbuffer =  0;
    }
    
    if ( _samplerenderbuffer != 0 ) {
        glDeleteFramebuffers(1, &_samplerenderbuffer);
        _samplerenderbuffer =  0;
    }
}

@end
