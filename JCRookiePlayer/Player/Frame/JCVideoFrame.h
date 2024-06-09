//
//  JCVideoFrame.h
//  JCImage
//
//  Created by jaycehan on 2024/2/5.
//

#import <Foundation/Foundation.h>
#import "avformat.h"
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, JCFrameType) {
    JCFrameTypeVideo = 0,   // 视频帧
    JCFrameTypeAudio = 1,   // 音频帧
};

@protocol JCFrame <NSObject>

// 帧类型
@property (nonatomic, assign, readonly) JCFrameType type;

// 帧时长
@property (nonatomic, assign, readonly) CGFloat duration;

// 帧位置
@property (nonatomic, assign, readonly) CGFloat position;

// 构造方法
- (instancetype)initWithAVFrame:(AVFrame *)frame;

@end

@protocol JCVideoFrame <JCFrame>
// 高度
@property (nonatomic, assign, readonly) NSUInteger height;

// 宽度
@property (nonatomic, assign, readonly) NSUInteger width;

// 亮度
@property (nonatomic, strong, readonly) NSData *luminance;

// 色度
@property (nonatomic, strong, readonly) NSData *chrominance;

// 浓度
@property (nonatomic, strong, readonly) NSData *chroma;

@end

@protocol JCAudioFrame <JCFrame>

@property (nonatomic, strong, readonly) NSData *sampleData;

@end

#pragma mark --

@protocol JCPlayerInfo <NSObject>

@end

@protocol JCVideoInfo <JCPlayerInfo>
// 视频时长（毫秒）
@property (nonatomic, assign, readonly) NSTimeInterval duration;

// 视频宽度
@property (nonatomic, assign, readonly) NSUInteger width;

// 视频高度
@property (nonatomic, assign, readonly) NSUInteger height;

// 视频帧率
@property (nonatomic, assign, readonly) NSUInteger fps;

@end

@protocol JCAudioInfo <JCPlayerInfo>

// 采样率
@property (nonatomic, assign, readonly) CGFloat sampleRate;

// 声道数
@property (nonatomic, assign, readonly) CGFloat channels;

// 采样格式
@property (nonatomic, assign, readonly) enum AVSampleFormat sampleFormat;

// 编码音频数据的位数
@property (nonatomic, assign, readonly) NSUInteger codedSampleBits;

@end


NS_ASSUME_NONNULL_END
/*
 sample_rate(采样率):每秒钟采样次数，单位Hz。通话时为8000Hz，媒体采样率为44100Hz
 sample_bits(位深度):采样精度，位深度决定动态范围。采样时为每个采样指定最接近原始声波振幅的振幅值。
 channel(声道数):采样时用到的麦克风数量，声道数越多越能还原真实的采样环境(立体声).
*/
