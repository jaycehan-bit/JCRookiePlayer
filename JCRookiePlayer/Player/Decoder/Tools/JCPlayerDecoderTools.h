//
//  JCPlayerDecoderTools.h
//  JCImage
//
//  Created by jaycehan on 2024/3/14.
//

#import <Foundation/Foundation.h>
#import "avformat.h"

NS_ASSUME_NONNULL_BEGIN

@interface JCPlayerDecoderTools : NSObject

/**
 * @brief 获取视频文件制定格式的流索引
 * @param format_context 文件格式上下文
 * @param media_type 需要寻找的媒体类型
 * @return NSArray<NSNumber *> 索引列表
 */
NSArray<NSNumber *> *findStreamIndex(const AVFormatContext *format_context, const enum AVMediaType media_type);

/**
 * @brief 获取视频文件FPS和时间基
 * @param stream 流
 */
void streamFPSTimeBase(const AVStream *stream, CGFloat *FPS, CGFloat *timeBase);


/**
 * @brief 获取视频文件格式上下问
 * @param URL 视频文件地址
 * @return AVFormatContext * 上下文
 */
AVFormatContext *formate_context(NSString *URL);

@end

NS_ASSUME_NONNULL_END
