//
//  JCPlayerSyncController.m
//  JCImage
//
//  Created by jaycehan on 2024/3/13.
//

#import "JCPlayerDecoder.h"
#import "JCPlayerSyncController.h"

static const NSTimeInterval gJCPlayerMinimumDuration = 2.0;
static const NSTimeInterval gJCPlayerMaximumGap = 0.05;

@interface JCPlayerSyncController ()
// 解码器
@property (nonatomic, strong) JCPlayerDecoder *decoder;
// 解码的视频帧
@property (nonatomic, strong) NSMutableArray<id<JCVideoFrame>> *videoFrameQueue;
// 解码的音频帧
@property (nonatomic, strong) NSMutableArray<id<JCAudioFrame>> *audioFrameQueue;
// 当前正在渲染的视频帧
@property (nonatomic, strong) id<JCVideoFrame> currentVideoFrame;
// 当前正在渲染的音频帧
@property (nonatomic, strong) id<JCAudioFrame> currentAudioFrame;
// 当前正在渲染的音频帧的偏移
@property (nonatomic, assign) NSUInteger currentAudioFrameOffset;
// 音频渲染偏移
@property (nonatomic, assign) NSTimeInterval audioPosition;
// 解码队列
@property (nonatomic, strong) dispatch_queue_t decodeQueue;

@property (nonatomic, strong) NSLock *frameQueueLock;

@property (nonatomic, strong) NSLock *controlLock;

@property (nonatomic, assign, getter=isRunning) BOOL running;

@property (nonatomic, strong) dispatch_semaphore_t semaphore;
// 已解码长度
@property (nonatomic, assign) NSTimeInterval decodedDuration;

@property (nonatomic, strong) NSHashTable<id<JCPlayerDecoderMonitor>> *monitors;

@end

@implementation JCPlayerSyncController

- (instancetype)init {
    self = [super init];
    if (self) {
        _controlLock = [[NSLock alloc] init];
        _frameQueueLock = [[NSLock alloc] init];
        _decoder = [[JCPlayerDecoder alloc] init];
        _videoFrameQueue = [NSMutableArray array];
        _audioFrameQueue = [NSMutableArray array];
    }
    return self;
}

- (id<JCPlayerVideoContext>)openFileWithFilePath:(NSString *)filePath {
    NSError *error = nil;
    id<JCPlayerVideoContext> videoContext = [self.decoder openFileWithFilePath:filePath error:&error];
    if (!error && videoContext) {
        [self startDecodingLoop];
        return videoContext;
    }
    return nil;
}

- (void)openFileWithFilePath:(NSString *)filePath finishBlock:(void(^)(id<JCPlayerVideoContext>))finishBlock {
    [self dispatchStateEventWithState:JCPlayerStatePreparing];
    dispatch_async(self.decodeQueue, ^{
        id<JCPlayerVideoContext> context = [self openFileWithFilePath:filePath];
        dispatch_async(dispatch_get_main_queue(), ^{
            finishBlock ? finishBlock(context) : nil;
        });
    });
}

- (void)fillAudioRenderDataWithBuffer:(SInt16 *)buffer byteSize:(uint32_t)byteSize {
    while (byteSize > 0) {
        if (!self.currentAudioFrame) {
            self.currentAudioFrame = self.audioFrameQueue.firstObject;
            self.currentAudioFrameOffset = 0;
            if (!self.currentAudioFrame) {
                return;
            }
            self.audioPosition = self.currentAudioFrame.position;
            self.decodedDuration -= self.currentAudioFrame.duration;
            [self.frameQueueLock lock];
            [self.audioFrameQueue removeObjectAtIndex:0];
            [self.frameQueueLock unlock];
        }
        // 当前音频帧未读完
        const void *bytes = self.currentAudioFrame.sampleData.bytes + self.currentAudioFrameOffset;
        size_t copySize = MIN(byteSize, self.currentAudioFrame.sampleData.length - self.currentAudioFrameOffset);
        memcpy(buffer, bytes, copySize);
        byteSize -= copySize;
        buffer += copySize / sizeof(SInt16);
        if (copySize < self.currentAudioFrame.sampleData.length - self.currentAudioFrameOffset) {
            // 当前帧未读取完
            self.currentAudioFrameOffset += copySize;
        } else {
            // 当前帧读取完
            self.currentAudioFrame = nil;
            self.currentAudioFrameOffset = 0;
        }
    }
    if (self.decodedDuration < gJCPlayerMinimumDuration) {
        dispatch_semaphore_signal(self.semaphore);
    }
}

- (id<JCVideoFrame>)renderedVideoFrame {
    id<JCVideoFrame> videoFrame = self.videoFrameQueue.firstObject;
    if (!videoFrame || videoFrame.position - self.audioPosition > gJCPlayerMaximumGap) {
        // 视频快于音频,继续渲染当前帧
        return nil;
    }
    [self.frameQueueLock lock];
    [self.videoFrameQueue removeObjectAtIndex:0];
    while (self.audioPosition - videoFrame.position > gJCPlayerMaximumGap && videoFrame) {
        // 音频快于视频,丢弃部分视频帧
        [self.videoFrameQueue removeObjectAtIndex:0];
        videoFrame = self.videoFrameQueue.firstObject;
    }
    [self.frameQueueLock unlock];
    return videoFrame;
}

#pragma mark - Decoding Logic

- (void)startDecodingLoop {
    __block dispatch_block_t callBack = ^{
        [self dispatchStateEventWithState:JCPlayerStatePrepared];
    };
    self.semaphore = dispatch_semaphore_create(1);
    dispatch_async(self.decodeQueue, ^{
        while (!self.decoder.isFinish) {
            dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
            while (self.decodedDuration < gJCPlayerMinimumDuration) {
                @autoreleasepool {
                    NSError *error = nil;
                    NSArray<id<JCFrame>> * frames = [self.decoder decodeVideoFramesWithDuration:0.5 error:&error];
                    if (error.code == JCDecodeErrorCodeEOF) {
                        error = nil;
                        // 解码完成
                        break;
                    }
                    for (id<JCFrame> frame in frames) {
                        if (frame.type == JCFrameTypeAudio) {
                            [self.audioFrameQueue addObject:(id<JCAudioFrame>)frame];
                            self.decodedDuration += frame.duration;
                        }
                        if (frame.type == JCFrameTypeVideo) {
                            [self.videoFrameQueue addObject:(id<JCVideoFrame>)frame];
                        }
                    }
                }
            }
            callBack ? callBack() : nil;
            callBack = nil;
        }
    });
}

#pragma mark - Decoding Control

- (void)run {
    if (self.isRunning) {
        return;
    }
    [self.controlLock lock];
    self.running = YES;
    [self.controlLock unlock];
}

- (void)stop {
    if (!self.isRunning) {
        return;
    }
    [self.controlLock lock];
    self.running = NO;
    [self.controlLock unlock];
}

- (dispatch_queue_t)decodeQueue {
    if (!_decodeQueue) {
        _decodeQueue = dispatch_queue_create("com.github.jaycehan.decodequeue", DISPATCH_QUEUE_SERIAL);
    }
    return _decodeQueue;
}

#pragma mark -- Monitor

- (void)dispatchStateEventWithState:(JCPlayerState)state {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self dispatchStateEventWithState:state];
        });
        return;
    }
    for (id<JCPlayerDecoderMonitor> monitor in self.monitors.objectEnumerator) {
        if ([monitor respondsToSelector:@selector(playerController:stateChanges:)]) {
            [monitor playerController:self stateChanges:state];
        }
    }
}

- (void)registerPlayerStateMonitor:(id<JCPlayerDecoderMonitor>)monitor {
    if (!monitor || [self.monitors containsObject:monitor]) {
        return;
    }
    [self.monitors addObject:monitor];
}

- (void)unregisterPlayerStateMonitor:(id<JCPlayerDecoderMonitor>)monitor {
    if (!monitor || ![self.monitors containsObject:monitor]) {
        return;
    }
    [self.monitors removeObject:monitor];
}

- (NSHashTable *)monitors {
    if (!_monitors) {
        _monitors = [NSHashTable weakObjectsHashTable];
    }
    return _monitors;
}

@end
