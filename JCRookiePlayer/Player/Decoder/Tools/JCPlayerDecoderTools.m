//
//  JCPlayerDecoderTools.m
//  JCImage
//
//  Created by jaycehan on 2024/3/14.
//

#import "avformat.h"
#import "JCPlayerDecoderTools.h"

@implementation JCPlayerDecoderTools

NSArray *findStreamIndex(const AVFormatContext *format_context, const enum AVMediaType media_type) {
    NSMutableArray *indexArray = [NSMutableArray array];
    for (NSUInteger index = 0; index < format_context->nb_streams; index++) {
        if (format_context->streams[index]->codecpar->codec_type == media_type) {
            [indexArray addObject:@(index)];
        }
    }
    return indexArray.copy;
}

void streamFPSTimeBase(const AVStream *stream, CGFloat *FPS, CGFloat *timeBase) {
    if (stream->time_base.den && stream->time_base.num) {
        *timeBase = av_q2d(stream->time_base);
    }
    if (stream->avg_frame_rate.den && stream->avg_frame_rate.num) {
        *FPS = av_q2d(stream->avg_frame_rate);
    } else if (stream->r_frame_rate.den && stream->r_frame_rate.num) {
        *FPS = av_q2d(stream->r_frame_rate);
    } else if (*timeBase > 0){
        *FPS = 1.0 / *timeBase;
    }
}

AVFormatContext * formate_context(NSString *URL) {
    AVFormatContext *formatContext = avformat_alloc_context();
    const char *url = [URL UTF8String];
    int node_result = avformat_open_input(&formatContext, url, NULL, NULL);
    if (node_result != 0) {
        NSLog(@"❌❌❌ Open input failed with errorCode:%d", node_result);
    }
    node_result = avformat_find_stream_info(formatContext, NULL);
    if (node_result < 0) {
        NSLog(@"❌❌❌ Find stream info failed with errorCode:%d", node_result);
    }
    
    if (node_result < 0) {
        avformat_close_input(&formatContext);
        avformat_free_context(formatContext);
    }
    return formatContext;
}

@end
