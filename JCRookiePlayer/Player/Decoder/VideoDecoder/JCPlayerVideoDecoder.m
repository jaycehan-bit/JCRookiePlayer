//
//  JCPlayerVideoDecoder.m
//  JCImage
//
//  Created by jaycehan on 2023/12/28.
//

#import <libavutil/frame.h>
#import "avformat.h"
#import "JCPlayerAsynModuleDefine.h"
#import "JCPlayerDecoderTools.h"
#import "JCPlayerVideoDecoder.h"
#import "JCPlayerVideoFrame+Writable.h"
#import "JCPlayerVideoInfo.h"

static NSUInteger I = 0;
static NSUInteger B = 0;
static NSUInteger P = 0;
static NSUInteger O = 0;

@interface JCPlayerVideoDecoder ()

@property (nonatomic, assign) AVFormatContext *format_context;

@property (nonatomic, assign) AVCodecContext *codec_context;

@property (nonatomic, assign) NSInteger stream_index;

@property (nonatomic, assign) CGFloat timeBase;

@property (nonatomic, assign) CGFloat FPS;

@end

@implementation JCPlayerVideoDecoder

@dynamic valid;

- (instancetype)init {
    self = [super init];
    if (self) {
        _stream_index = JCPlayerInvalidStreamIndex;
    }
    return self;
}

#pragma make - <JCPlayerVideoDecoder>

- (BOOL)valid {
    return self.stream_index != JCPlayerInvalidStreamIndex;
}
- (id<JCPlayerInfo>)openFileWithFormatContext:(AVFormatContext *)formatContext error:(NSError **)error {
    self.format_context = formatContext;
    self.stream_index = findStreamIndex(self.format_context, AVMEDIA_TYPE_VIDEO).firstObject.integerValue;
    AVStream *stream = self.format_context->streams[self.stream_index];
    streamFPSTimeBase(stream, &_FPS, &_timeBase);
    
    AVCodec *codec = avcodec_find_decoder(stream->codecpar->codec_id);
    self.codec_context = avcodec_alloc_context3(codec);
    avcodec_parameters_to_context(self.codec_context, stream->codecpar);

    int avcodec_open2_result = avcodec_open2(self.codec_context, codec, NULL);
    if (avcodec_open2_result != 0) {
        *error = [NSError errorWithDomain:NSCocoaErrorDomain code:JCDecodeErrorCodecOpenCodecError userInfo:@{NSLocalizedFailureReasonErrorKey : @"Open Codec Error"}];
        return nil;
    }
    AVStream *videoStream = self.format_context->streams[self.stream_index];
    JCPlayerVideoInfo *videoInfo = [[JCPlayerVideoInfo alloc] init];
    videoInfo.fps = av_q2d(videoStream->avg_frame_rate);
    videoInfo.duration = (NSTimeInterval)videoStream->duration * self.timeBase;
    videoInfo.width = self.codec_context->width;
    videoInfo.height = self.codec_context->height;
    return videoInfo;
}

- (NSArray<id<JCFrame>> *)decodeVideoFrameWithPacket:(AVPacket)packet error:(NSError **)error {
    NSAssert(packet.stream_index == self.stream_index, @"❌❌❌[Mismatched packet type]");
    int send_packet_result = avcodec_send_packet(self.codec_context, &packet);
    if (send_packet_result != 0) {
        NSLog(@"❌❌❌ Fail to send video packet with error code : %d", send_packet_result);
        *error = [NSError errorWithDomain:NSCocoaErrorDomain code:JCDecodeErrorCodeSendPacket userInfo:@{NSLocalizedFailureReasonErrorKey : @"Send packet error"}];
        return nil;
    }
    AVFrame *frame = av_frame_alloc();
    int receive_frame_result = avcodec_receive_frame(self.codec_context, frame);
    if (receive_frame_result == AVERROR(EAGAIN)) {
        // 解码数据不够，需继续send_packet
//        NSLog(@"⚠️⚠️⚠️ Fail to receive frame with AVERROR error : %d", receive_frame_result);
        if (error) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:JCDecodeErrorCodeEAGAIN userInfo:@{NSLocalizedFailureReasonErrorKey : @"EAGAIN Error"}];
        }
    } else if (receive_frame_result == AVERROR_EOF) {
        if (error) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:JCDecodeErrorCodeEOF userInfo:@{NSLocalizedFailureReasonErrorKey : @"EOF Error"}];
        }
    } else if (receive_frame_result != 0) {
        NSLog(@"❌❌❌ Fail to receive frame with error code : %d", receive_frame_result);
        if (error) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:receive_frame_result userInfo:@{NSLocalizedFailureReasonErrorKey : @"Receive frame Error"}];
        }
    } else {
//        switch (frame->pict_type) {
//            case AV_PICTURE_TYPE_I:
//                I += 1;
//                break;
//            case AV_PICTURE_TYPE_P:
//                P += 1;
//                break;
//            case AV_PICTURE_TYPE_B:
//                B += 1;
//                break;
//            case AV_PICTURE_TYPE_S:
//            case AV_PICTURE_TYPE_SI:
//            case AV_PICTURE_TYPE_SP:
//            case AV_PICTURE_TYPE_BI:
//                O += 1;
//                break;
//            default:
//                break;
//        }
//        NSLog(@"I: %lu -- B: %lu -- P : %lu -- Other: %lu", (unsigned long)I, (unsigned long)B, (unsigned long)P, (unsigned long)O);
//        NSLog(@"✅✅✅ Receive frame success");
        JCPlayerVideoFrame *videoFrame = [[JCPlayerVideoFrame alloc] initWithAVFrame:frame];
        videoFrame.duration = frame->pkt_duration * self.timeBase;
        videoFrame.position = frame->pts * self.timeBase;
        av_frame_free(&frame);
        return @[videoFrame];
    }
    av_frame_free(&frame);
    return nil;
}

@end
