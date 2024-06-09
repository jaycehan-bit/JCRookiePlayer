//
//  JCPlayerVideoInfo.h
//  JCImage
//
//  Created by jaycehan on 2024/3/8.
//

#import <Foundation/Foundation.h>
#import "JCVideoFrame.h"

NS_ASSUME_NONNULL_BEGIN

@interface JCPlayerVideoInfo : NSObject <JCVideoInfo>

// 视频时长（毫秒）
@property (nonatomic, assign) NSTimeInterval duration;

// 视频宽度
@property (nonatomic, assign) NSUInteger width;

// 视频高度
@property (nonatomic, assign) NSUInteger height;

// 视频帧率
@property (nonatomic, assign) NSUInteger fps;

@end

@interface JCPlayerAudioInfo : NSObject <JCAudioInfo>

// 采样率
@property (nonatomic, assign) CGFloat sampleRate;

// 声道数
@property (nonatomic, assign) CGFloat channels;

// 采样格式
@property (nonatomic, assign) enum AVSampleFormat sampleFormat;

// 编码音频数据的位数
@property (nonatomic, assign) NSUInteger codedSampleBits;

@end

NS_ASSUME_NONNULL_END
