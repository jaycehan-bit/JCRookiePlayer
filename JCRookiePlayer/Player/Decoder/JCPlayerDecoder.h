//
//  JCPlayerDecoder.h
//  JCImage
//
//  Created by jaycehan on 2024/2/21.
//

#import <Foundation/Foundation.h>
#import "JCPlayerVideoContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface JCPlayerDecoder : NSObject
/**
 * 是否解码完成（EOF）
 */
@property (nonatomic, assign, readonly, getter=isFinish) BOOL finish;

/**
 * @brief 打开视频文件，读取视频信息
 * @param filePath 目标文件路径
 * @param error 错误
 * @return 视频信息
 */
- (id<JCPlayerVideoContext>)openFileWithFilePath:(NSString *)filePath error:(NSError **)error;

/**
 * @brief 解码一段视频帧
 * @param duration 解码视频时长，可能稍微超出
 * @param error 错误信息
 * @return 解码数据
 */
- (NSArray<id<JCFrame>> *)decodeVideoFramesWithDuration:(CGFloat)duration error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
