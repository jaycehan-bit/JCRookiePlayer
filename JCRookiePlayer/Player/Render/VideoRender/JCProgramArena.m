//
//  JCProgramArena.m
//  JCImage
//
//  Created by jaycehan on 2023/12/24.
//

#import <OpenGLES/gltypes.h>
#import <OpenGLES/ES3/gl.h>
#import "JCProgramArena.h"
#import "JCProgramProvider.h"

@interface JCProgramArena ()

@property (nonatomic, assign) GLuint program;

@property (nonatomic, assign) GLuint positionAttribute;

@property (nonatomic, assign) GLuint textureUniform;

@property (nonatomic, assign) GLuint textureCoordinateAttribute;

@property (nonatomic, assign) GLuint textureID;

@end

@implementation JCProgramArena

+ (NSString *)defaultVertexShaderFilePath {
    return [NSBundle.mainBundle pathForResource:@"VertexShader" ofType:@"vsh"];
}

+ (NSString *)defaultFragShaderFilePath {
    return [NSBundle.mainBundle pathForResource:@"FragShader" ofType:@"fsh"];
}

- (void)perpare {
    if (![self perpareProgram]) {
        return;
    }
    [self perpareRenderParams];
}

- (void)destory {
    if (self.program) {
        glDeleteProgram(self.program);
        self.program = 0;
    }
    if(self.textureID) {
        glDeleteTextures(1, &_textureID);
    }
}

- (BOOL)perpareProgram {
    GLuint vertexShader;
    [JCProgramProvider shader:&vertexShader type:GL_VERTEX_SHADER filePath:[JCProgramArena defaultVertexShaderFilePath]];
    GLuint fragShader;
    [JCProgramProvider shader:&fragShader type:GL_FRAGMENT_SHADER filePath:[JCProgramArena defaultFragShaderFilePath]];
    [JCProgramProvider program:&_program vertexShader:vertexShader fragSharder:fragShader];
    glLinkProgram(_program);
    glDeleteShader(vertexShader);
    glDeleteShader(fragShader);

    GLint status;
    glGetProgramiv(self.program, GL_LINK_STATUS, &status);
    if (status == GL_FALSE) {
        NSLog(@"Program perpare failed");
    }
    return status;
}

- (BOOL)perpareRenderParams {
    // 创建纹理对象
    glGenTextures(1, &_textureID);
    // 绑定句柄
    glBindTexture(GL_TEXTURE_2D, self.textureID);
    // 设置过滤方式（缩放规则）为双线性过滤
    // GL_LINEAR（双线性过滤）：四个相邻的纹理元素之间使用线性插值
    // GL_NEAREST（最邻近过滤）：每个片段选择最近的纹理元素填充
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    // 设置超出坐标轴的纹理处理规则
    // GL_CLAMP_TO_EDGE：超出1的部分使用1这个点的像素来填充，小于0的部分使用0点来填充
    // GL_REPEAT：超出1的部分会从0再渲染一遍
    // GL_MIRRORED_REPEAT：镜像平铺
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 0, 0, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
    glBindTexture(GL_TEXTURE_2D, 0);
    return YES;
}

- (void)renderForFrame:(uint8_t *)frame size:(CGSize)size {
    glUseProgram(self.program);
    glClearColor(0.0, 0.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glBindTexture(GL_TEXTURE_2D, self.textureID);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)size.width, (GLsizei)size.height,
                 0, GL_RGBA, GL_UNSIGNED_BYTE, frame);
    static const GLfloat imageVertices[] = {
            -1.0f, -1.0f,
            1.0f, -1.0f,
            -1.0f,  1.0f,
            1.0f,  1.0f,
        };
        
    GLfloat noRotationTextureCoordinates[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };
    
    glVertexAttribPointer([self position], 2, GL_FLOAT, 0, 0, imageVertices);
    glEnableVertexAttribArray([self position]);
    glVertexAttribPointer([self texcoord], 2, GL_FLOAT, 0, 0, noRotationTextureCoordinates);
    glEnableVertexAttribArray([self texcoord]);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _textureID);
    glUniform1i([self textureUniform], 0);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

- (int)position {
    return glGetAttribLocation(_program, "position");
}

- (int)texcoord {
    return glGetAttribLocation(_program, "texcoord");
}

- (GLuint)textureUniform {
    return glGetUniformLocation(_program, "texSampler");
}

@end

