//
//  JCPlayerAudioDecoder.m
//  JCImage
//
//  Created by jaycehan on 2024/1/15.
//

#import <libavformat/avformat.h>
#import <libavutil/samplefmt.h>
#import <libswresample/swresample.h>
#import "avformat.h"
#import "JCPlayerAsynModuleDefine.h"
#import "JCPlayerAudioDecoder.h"
#import "JCPlayerAudioFrame+Writable.h"
#import "JCPlayerDecoderTools.h"
#import "JCPlayerVideoInfo.h"

const static int gJCPlayerAudioSample = 44100;

@interface JCPlayerAudioDecoder ()

@property (nonatomic, assign) AVFormatContext *format_context;

@property (nonatomic, assign) AVCodecContext *codec_context;

@property (nonatomic, assign) SwrContext *swr_context;

@property (nonatomic, assign) NSInteger stream_index;

@property (nonatomic, assign) CGFloat timeBase;

@property (nonatomic, assign) CGFloat FPS;

@end

@implementation JCPlayerAudioDecoder

@dynamic valid;

- (instancetype)init {
    self = [super init];
    if (self) {
        self.stream_index = JCPlayerInvalidStreamIndex;
    }
    return self;
}

#pragma mark - <JCPlayerAudioDecoder>

- (BOOL)valid {
    return self.stream_index != JCPlayerInvalidStreamIndex;
}

- (id<JCPlayerInfo>)openFileWithFormatContext:(AVFormatContext *)formatContext error:(NSError *__autoreleasing  _Nullable *)error {
    self.format_context = formatContext;
    self.stream_index = findStreamIndex(self.format_context, AVMEDIA_TYPE_AUDIO).firstObject.integerValue;
    AVStream *stream = self.format_context->streams[self.stream_index];
    streamFPSTimeBase(stream, &_FPS, &_timeBase);
    
    AVCodec *codec = avcodec_find_decoder(stream->codecpar->codec_id);
    self.codec_context = avcodec_alloc_context3(codec);
    avcodec_parameters_to_context(self.codec_context, stream->codecpar);

    int avcodec_open2_result = avcodec_open2(self.codec_context, codec, NULL);
    if (avcodec_open2_result != 0) {
        *error = [NSError errorWithDomain:NSCocoaErrorDomain code:JCDecodeErrorCodecOpenCodecError userInfo:@{NSLocalizedFailureReasonErrorKey : @"Open Codec Error"}];
        NSLog(@"❌❌❌ Failed to open codec");
    }
    [self configSwtContextIfNeeded];
    JCPlayerAudioInfo *audioInfo = [[JCPlayerAudioInfo alloc] init];
    audioInfo.channels = self.codec_context->channels;
    audioInfo.sampleRate = self.codec_context->sample_rate;
    audioInfo.sampleFormat = self.codec_context->sample_fmt;
    audioInfo.codedSampleBits = self.codec_context->bits_per_coded_sample;
    return audioInfo;
}

- (NSArray<id<JCFrame>> *)decodeVideoFrameWithPacket:(AVPacket)packet error:(NSError **)error {
    NSAssert(packet.stream_index == self.stream_index, @"❌❌❌[Mismatched packet type]");
    int send_packet_result = avcodec_send_packet(self.codec_context, &packet);
    if (send_packet_result == AVERROR_EOF) {
        NSLog(@"✅✅✅ Send audio packet finish");
        return nil;
    } else if (send_packet_result != 0) {
        NSLog(@"❌❌❌ Fail to send audio packet with error code : %d", send_packet_result);
        return nil;
    } else {
    }
    NSMutableArray<id<JCFrame>> *frameBuffer = [NSMutableArray array];
    AVFrame *frame = av_frame_alloc();
    while (YES) {
        int receive_frame_result = avcodec_receive_frame(self.codec_context, frame);
        if (receive_frame_result == AVERROR(EAGAIN)) {
            // 解码数据不够，需继续send_packet
//            NSLog(@"⚠️⚠️⚠️ Fail to receive frame with AVERROR error : %d", receive_frame_result);
            if (error) {
                *error = [NSError errorWithDomain:NSCocoaErrorDomain code:JCDecodeErrorCodeEAGAIN userInfo:@{NSLocalizedFailureReasonErrorKey : @"EAGAIN Error"}];
            }
            break;
        } else if (receive_frame_result == AVERROR_EOF) {
            if (error) {
                *error = [NSError errorWithDomain:NSCocoaErrorDomain code:JCDecodeErrorCodeEOF userInfo:nil];
            }
            break;
        } else if (receive_frame_result != 0) {
            NSLog(@"❌❌❌ Fail to receive audio frame with error code : %d", receive_frame_result);
            if (error) {
                *error = [NSError errorWithDomain:NSCocoaErrorDomain code:JCDecodeErrorCodeReceiveFrame userInfo:@{NSLocalizedFailureReasonErrorKey : @"Receive Error"}];
            }
            break;
        } else {
            JCPlayerAudioFrame *audioFrame = [self convertAudioFrameWithAVFrame:frame];
            if (audioFrame) {
                [frameBuffer addObject:audioFrame];
            } else {
                break;
            }
        }
    }
    av_frame_free(&frame);
    return [frameBuffer copy];
}

#pragma mark - Private

- (JCPlayerAudioFrame *)convertAudioFrameWithAVFrame:(AVFrame *)frame {
    if (frame->data[0] == NULL) {
        return nil;
    }
    uint audioSize = av_samples_get_buffer_size(NULL, _codec_context->channels, frame->nb_samples, AV_SAMPLE_FMT_S16, 1);
    uint8_t *audioData = malloc(audioSize);
    Byte *outBuffer[2] = {audioData, 0};
    int numberOfFrame = 0;
    if (frame->format != AV_SAMPLE_FMT_S16) {
        numberOfFrame = swr_convert(self.swr_context, outBuffer, frame->nb_samples, (const uint8_t **)frame->data, frame->nb_samples);
    } else {
        audioData = frame->data[0];
        numberOfFrame = frame->nb_samples;
    }
    NSMutableData *pcm = [NSMutableData data];
    [pcm appendBytes:audioData length:audioSize];
    JCPlayerAudioFrame *audioFrame = [[JCPlayerAudioFrame alloc] initWithAVFrame:frame];
    audioFrame.position = frame->pts * self.timeBase;
    audioFrame.duration = frame->pkt_duration * self.timeBase;
    audioFrame.sampleData = pcm.copy;
    NSAssert(audioFrame.sampleData.length > 0, @"❌❌❌ Unpack Error");
    return audioFrame;
}

- (void)configSwtContextIfNeeded {
    if (self.codec_context->sample_fmt == AV_SAMPLE_FMT_S16) {
        return;
    }
    if (self.swr_context) {
        return;
    }
    enum AVSampleFormat in_format = self.codec_context->sample_fmt;
    int in_sample_rate = self.codec_context->sample_rate;
    uint64_t in_ch_layout = av_get_default_channel_layout(self.codec_context->channels);
    // 只修改format，不改变采样率
    enum AVSampleFormat out_format = AV_SAMPLE_FMT_S16;
    int out_sample_rate = self.codec_context->sample_rate;
    uint64_t out_ch_layout = av_get_default_channel_layout(self.codec_context->channels);
    
    self.swr_context = swr_alloc_set_opts(_swr_context,
                                          out_ch_layout,
                                          out_format,
                                          out_sample_rate,
                                          in_ch_layout,
                                          in_format,
                                          in_sample_rate,
                                          0, NULL);
    if (!self.swr_context) {
        NSLog(@"❌❌❌ Create swr_context failed");
        return;
    }
    if (swr_init(self.swr_context) != 0) {
        NSLog(@"❌❌❌ Init swr_context failed");
        swr_free(&_swr_context);
        return;
    }
}

@end
