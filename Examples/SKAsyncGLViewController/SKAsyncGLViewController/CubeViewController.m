//
//  ViewController.m
//  SKAsyncGLViewController
//
//  Created by Stephen Kopylov - Home on 27/04/16.
//  Copyright © 2016 test. All rights reserved.
//
#import "CubeViewController.h"
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/ES2/gl.h>
#import "CC3GLMatrix.h"

typedef struct {
    float Position[3];
    float Color[4];
} Vertex;

const Vertex Vertices[] = {
    { { 1,  -1,  0                                           }, { 1, 0, 0, 1 } },
    { { 1,  1,   0                                           }, { 1, 0, 0, 1 } },
    { { -1, 1,   0                                           }, { 0, 1, 0, 1 } },
    { { -1, -1,  0                                           }, { 0, 1, 0, 1 } },
    { { 1,  -1,  -1                                          }, { 1, 0, 0, 1 } },
    { { 1,  1,   -1                                          }, { 1, 0, 0, 1 } },
    { { -1, 1,   -1                                          }, { 0, 1, 0, 1 } },
    { { -1, -1,  -1                                          }, { 0, 1, 0, 1 } }
};

const GLubyte Indices[] = {
    // Front
    0, 1, 2,
    2, 3, 0,
    // Back
    4, 6, 5,
    4, 7, 6,
    // Left
    2, 7, 3,
    7, 6, 2,
    // Right
    0, 4, 1,
    4, 1, 5,
    // Top
    6, 2, 1,
    1, 6, 5,
    // Bottom
    0, 3, 7,
    0, 7, 4
};

@interface CubeViewController ()<SKAsyncGLViewControllerDelegate>

@property (nonatomic) GLuint positionSlot;
@property (nonatomic) GLuint colorSlot;
@property (nonatomic) GLuint projectionUniform;
@property (nonatomic) GLuint modelViewUniform;

@property (nonatomic) double multiplier;

@property (nonatomic) CGRect savedRect;
@property (nonatomic) UIBarButtonItem *playPauseButton;

@end

@implementation CubeViewController

#pragma mark - Lifecycle

- (void)loadView
{
    [super loadView];
    
    if ( _floating ) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        [button setImage:[UIImage imageNamed:@"Close"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
        
        
        NSDictionary *views = @{
                                @"btn": button
                                };
        
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[btn(30)]|" options:0 metrics:nil views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[btn(30)]" options:0 metrics:nil views:views]];
    }
    else {
        _playPauseButton = [[UIBarButtonItem alloc] initWithTitle:@"Pause" style:UIBarButtonItemStylePlain target:self action:@selector(playPause)];
        self.navigationItem.rightBarButtonItem = _playPauseButton;
        
        self.view.backgroundColor = [UIColor whiteColor];
    }
}


#pragma mark - private methods

- (void)buttonTapped
{
    [self willMoveToParentViewController:nil];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}


- (void)playPause
{
    self.paused = !self.paused;
    
    [_playPauseButton setTitle:self.paused ? @"Play" : @"Pause"];
}


#pragma mark - gl workaround

- (void)compileShaders
{
    GLuint vertexShader = [self compileShader:@"SimpleVertex"
                                     withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"SimpleFragment"
                                       withType:GL_FRAGMENT_SHADER];
    
    GLuint programHandle = glCreateProgram();
    
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    
    if ( linkSuccess == GL_FALSE ) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    glUseProgram(programHandle);
    
    _positionSlot = glGetAttribLocation(programHandle, "Position");
    _colorSlot = glGetAttribLocation(programHandle, "SourceColor");
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_colorSlot);
    _projectionUniform = glGetUniformLocation(programHandle, "Projection");
    _modelViewUniform = glGetUniformLocation(programHandle, "Modelview");
}


- (GLuint)compileShader:(NSString *)shaderName withType:(GLenum)shaderType
{
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:shaderName
                                                           ofType:@"glsl"];
    NSError *error;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath
                                                       encoding:NSUTF8StringEncoding error:&error];
    
    if ( !shaderString ) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    
    GLuint shaderHandle = glCreateShader(shaderType);
    
    const char *shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    glCompileShader(shaderHandle);
    
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    
    if ( compileSuccess == GL_FALSE ) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    return shaderHandle;
}


- (void)setupVBOs
{
    GLuint vertexBuffer;
    
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
}


#pragma mark - SKAsyncGLViewControllerDelegate

- (void)setupGL:(SKAsyncGLViewController *)viewController
{
    [super setupGL:viewController];
    [self compileShaders];
    [self setupVBOs];
}


- (void)drawGL:(CGRect)rect
{
    CC3GLMatrix *projection = [CC3GLMatrix matrix];
    float h = 4.0f * rect.size.height / rect.size.width;
    
    [projection populateFromFrustumLeft:-2 andRight:2 andBottom:-h / 2 andTop:h / 2 andNear:4 andFar:10];
    glUniformMatrix4fv(_projectionUniform, 1, 0, projection.glMatrix);
    
    _multiplier +=  1.5;
    
    CC3GLMatrix *modelView = [CC3GLMatrix matrix];
    [modelView populateFromTranslation:CC3VectorMake(sin(_multiplier / 20.0), 0, -7)];
    
    [modelView rotateBy:CC3VectorMake(_multiplier, _multiplier, 0)];
    glUniformMatrix4fv(_modelViewUniform, 1, 0, modelView.glMatrix);
    
    [super drawGL:rect];
}


- (void)drawGLInRect:(CGRect)rect
{
    glEnable(GL_DEPTH_TEST);
    
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE,
                          sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE,
                          sizeof(Vertex), (GLvoid *)(sizeof(float) * 3));
    
    glDrawElements(GL_TRIANGLES, sizeof(Indices) / sizeof(Indices[0]),
                   GL_UNSIGNED_BYTE, 0);
}


@end
