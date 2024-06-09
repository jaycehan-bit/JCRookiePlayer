//
//  JCProgramProvider.h
//  JCImage
//
//  Created by 智杰韩 on 2023/12/21.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/gltypes.h>

NS_ASSUME_NONNULL_BEGIN

@interface JCProgramProvider : NSObject

+ (void)shader:(GLuint *)shader type:(GLenum)type filePath:(NSString *)filePath;

+ (void)program:(GLuint *)program vertexShader:(GLuint)vertexShader fragSharder:(GLuint)fragShader;

@end

NS_ASSUME_NONNULL_END
