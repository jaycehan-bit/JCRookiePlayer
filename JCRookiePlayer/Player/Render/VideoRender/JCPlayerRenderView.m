//
//  JCPlayerRenderView.m
//  JCImage
//
//  Created by jaycehan on 2024/2/5.
//

#import <OpenGLES/ES3/gl.h>
#import "JCPlayerRenderView.h"
#import "JCProgramArena.h"
#import "JCProgramProvider.h"

/**
 * OpenGL坐标系
 * 左上角 [-1, 1]  右下角 [1,  -1]
 * iOS坐标系
 * 左上角[0, 0]，右下角[1, 1]
 * 需要在Y上乘以-1
 */
static const GLfloat vertices[] = {
    // 坐标              // 颜色                                // 纹理坐标
    // 左上角
    -1.0, -1, 0.0,     1.0, 0.0, 0.0,      0.0, 1.0,
    // 右上角
    1, -1, 0.0,     0.0, 1.0, 0.0,        1.0, 1.0,
    // 右下角
    1.0, 1.0, 0.0,     0.0, 0.0, 1.0,        1.0, 0.0,
    // 左下角
    -1.0, 1.0, 0.0,     0.0, 0.0, 0.0,        0.0, 0.0,
};


static const GLfloat indices[] = {
    0, 1, 2,    // 第一个三角形顶点
    0, 2, 3,    // 第二个三角形顶点
};

@interface JCPlayerRenderView () {
    GLuint _textures[3];
}

@property (nonatomic, strong) NSOperationQueue *renderQueue;

@property (nonatomic, strong) EAGLContext *EAGLContext;

@property (nonatomic, assign) GLuint program;

@property (nonatomic, strong) JCProgramArena *programProvider;

@property (nonatomic, strong) NSLock *lock;

@property (nonatomic, assign) unsigned int VAO;

@property (nonatomic, assign) unsigned int renderBuffer;

@property (nonatomic, assign) unsigned int frameBuffer;

@end

@implementation JCPlayerRenderView

+ (Class)layerClass {
    return CAEAGLLayer.class;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    CAEAGLLayer *layer = (CAEAGLLayer *)self.layer;
    layer.backgroundColor = UIColor.blackColor.CGColor;
    layer.opaque = YES;
    layer.drawableProperties = @{
        kEAGLDrawablePropertyRetainedBacking : @(NO),
        kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8,
    };
    return self;
}

#pragma mark - Texture

- (void)initializeTextureWithWidth:(GLsizei)width height:(GLsizei)height {
    glGenTextures(3, _textures);
    for (NSUInteger index = 0; index < 3; index ++) {
        glBindTexture(GL_TEXTURE_2D, _textures[index]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width, height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, NULL);
    }
    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void)generateTexturesWithVideoFrame:(id<JCVideoFrame>)videoFrame {
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _textures[0]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, (GLsizei)videoFrame.width, (GLsizei)videoFrame.height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, videoFrame.luminance.bytes);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _textures[1]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, (GLsizei)videoFrame.width / 2, (GLsizei)videoFrame.height  / 2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, videoFrame.chrominance.bytes);
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, _textures[2]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, (GLsizei)videoFrame.width  / 2, (GLsizei)videoFrame.height  / 2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, videoFrame.chroma.bytes);
    
    glUniform1i(glGetUniformLocation(self.program, "texture_Y"), 0);
    glUniform1i(glGetUniformLocation(self.program, "texture_U"), 1);
    glUniform1i(glGetUniformLocation(self.program, "texture_V"), 2);
}

#pragma mark - Render

- (void)prepareWithVideoInfo:(id<JCVideoInfo>)videoInfo {
    [EAGLContext setCurrentContext:self.EAGLContext];
    [self configRenderContext];
    [self compileProgramIfNeeded];
    [self initializeTextureWithWidth:(GLsizei)videoInfo.width height:(GLsizei)videoInfo.height];
    [self configOpenGLObjects];
    glViewport(0, 0, self.bounds.size.width, self.bounds.size.height);
}

#pragma mark - RenderBuffer

- (void)configRenderContext {
    glDeleteFramebuffers(1, &_frameBuffer);
    glDeleteRenderbuffers(1, &_renderBuffer);
    
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
    
    [self.EAGLContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];

    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"✅✅✅ Framebuffer config success");
    } else {
        GLenum glError = glGetError();
        NSLog(@"❌❌❌ Fail to config framebuffer with error:%x", glError);
    }
}

#pragma mark - GLObjects

- (void)configOpenGLObjects {
    glGenVertexArrays(1, &_VAO);
    glBindVertexArray(self.VAO);
    
    GLuint VBO;
    glGenBuffers(1, &VBO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_DYNAMIC_DRAW);
    
    GLuint EBO;
    glGenBuffers(1, &EBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_DYNAMIC_DRAW);
    
    glVertexAttribPointer(glGetAttribLocation(self.program, "position"), 3, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), (void *)0);
    glEnableVertexAttribArray(glGetAttribLocation(self.program, "position"));

    glVertexAttribPointer(glGetAttribLocation(self.program, "color"), 3, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), (void *)(3 * sizeof(GLfloat)));
    glEnableVertexAttribArray(glGetAttribLocation(self.program, "color"));

    glVertexAttribPointer(glGetAttribLocation(self.program, "texcoord"), 2, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), (void *)(6 * sizeof(GLfloat)));
    glEnableVertexAttribArray(glGetAttribLocation(self.program, "texcoord"));
}

- (void)compileProgramIfNeeded {
    GLuint vertexShader;
    [JCProgramProvider shader:&vertexShader type:GL_VERTEX_SHADER filePath:[NSBundle.mainBundle pathForResource:@"JCPlayerVertexShader" ofType:@"vsh"]];
    GLuint fragShader;
    [JCProgramProvider shader:&fragShader type:GL_FRAGMENT_SHADER filePath:[NSBundle.mainBundle pathForResource:@"JCPlayerFragShader" ofType:@"fsh"]];

    [JCProgramProvider program:&_program vertexShader:vertexShader fragSharder:fragShader];

    glLinkProgram(self.program);
    glDeleteShader(vertexShader);
    glDeleteShader(fragShader);

    GLint status;
    glGetProgramiv(self.program, GL_LINK_STATUS, &status);
    if (status == GL_FALSE) {
        NSLog(@"❌❌❌ Fail to compile program");
        return;
    } else {
        NSLog(@"✅✅✅ Program complie success");
    }
    glUseProgram(self.program);
}

#pragma mark - RenderOperation

- (void)renderVideoFrame:(id<JCVideoFrame>)videoFrame {
    @autoreleasepool {
        __weak typeof(self) weakSelf = self;
        NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            if (!weakSelf || !videoFrame) {
                return;
            }
            [EAGLContext setCurrentContext:weakSelf.EAGLContext];
            glClearColor(0.0, 0.0, 0.0, 1.0);
            glClear(GL_COLOR_BUFFER_BIT);
            glUseProgram(weakSelf.program);
            [weakSelf generateTexturesWithVideoFrame:videoFrame];
            glBindVertexArray(weakSelf.VAO);
            glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
            [weakSelf.EAGLContext presentRenderbuffer:GL_RENDERBUFFER];
        }];
        [self.renderQueue addOperation:operation];
    }
}

#pragma mark - Initialize

- (NSOperationQueue *)renderQueue {
    if (!_renderQueue) {
        _renderQueue = [[NSOperationQueue alloc] init];
        _renderQueue.maxConcurrentOperationCount = 1;
    }
    return _renderQueue;
}

- (JCProgramArena *)programProvider {
    if (!_programProvider) {
        _programProvider = [[JCProgramArena alloc] init];
    }
    return _programProvider;
}

- (EAGLContext *)EAGLContext {
    if (!_EAGLContext) {
        _EAGLContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    }
    return _EAGLContext;
}

@end
