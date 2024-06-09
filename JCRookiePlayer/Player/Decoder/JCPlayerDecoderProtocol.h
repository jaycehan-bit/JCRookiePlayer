//
//  JCPlayerDecoderProtocol.h
//  JCImage
//
//  Created by jaycehan on 2024/3/14.
//

#import <Foundation/Foundation.h>
#import "JCVideoFrame.h"

NS_ASSUME_NONNULL_BEGIN

@protocol JCPlayerDecoder <NSObject>

/**
 * @brief 当前视频文件音频或视频是否有效
 */
@property (nonatomic, assign, readonly) BOOL valid;

/**
 * @brief 视频/音频时间基
 */
@property (nonatomic, assign, readonly) CGFloat timeBase;

/**
 * @brief 视频/音频流索引
 */
@property (nonatomic, assign, readonly) NSInteger stream_index;

/**
 * @brief 视频/音频帧数
 */
@property (nonatomic, assign, readonly) CGFloat FPS;

/**
 * @brief 读取视频文件数据
 * @param formatContext 视频文件格式上下文
 * @param error 错误信息
 */
- (id<JCPlayerInfo>)openFileWithFormatContext:(AVFormatContext *)formatContext error:(NSError **)error;

/**
 * @brief 解码视频帧
 * @param packet 视频帧
 * @param error 错误信息
 */
- (NSArray<id<JCFrame>> *)decodeVideoFrameWithPacket:(AVPacket)packet error:(NSError **)error;

@end


@protocol JCPlayerVideoDecoder <JCPlayerDecoder>

@end


@protocol JCPlayerAudioDecoder <JCPlayerDecoder>

@end

NS_ASSUME_NONNULL_END
