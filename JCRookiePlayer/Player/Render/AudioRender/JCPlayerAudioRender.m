//
//  JCPlayerAudioRender.m
//  JCImage
//
//  Created by jaycehan on 2024/3/18.
//

#import <AudioToolbox/AUComponent.h>
#import <AudioToolbox/AudioComponent.h>
#import <AudioToolbox/AudioOutputUnit.h>
#import <AudioToolbox/AudioUnitProperties.h>
#import <AVFAudio/AVAudioSession.h>
#import "JCPlayerAudioRender.h"

#define K_OUTPUT 0
#define K_INPUT 0

@interface JCPlayerAudioRender ()

@property (nonatomic, assign) AudioUnit audioUnit;

@property (nonatomic, strong) id<JCAudioInfo> audioInfo;
           
@property (nonatomic, weak) id<JCPlayerAudioRenderDataSource> dataSource;

@end

@implementation JCPlayerAudioRender

- (instancetype)initWithDataSource:(id<JCPlayerAudioRenderDataSource>)dataSource {
    self = [super init];
    self.dataSource = dataSource;
    return self;
}

- (void)prepareWithVideoInfo:(id<JCAudioInfo>)videoInfo {
    if (!videoInfo) {
        return;
    }
    self.audioInfo = videoInfo;
    NSError *error = [self initializeAudioSession];
    if (error) {
        return;
    }
    [self configAudioComponentInstance];
    [self configAudioUnitEnableIO];
    [self configAudioStreamFormatWithAudioInfo:videoInfo];
    [self configAudioRenderCallBack];
    OSStatus status = AudioUnitInitialize(_audioUnit);
    if (status != noErr) {
        NSLog(@"❌❌❌ Fail to initialize AudioUnit");
    }
}

- (NSError *)initializeAudioSession {
    NSError *error = nil;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (error) {
        NSLog(@"❌❌❌ Fail to init audioSession");
        return error;
    }
    [audioSession setActive:YES error:&error];
    if (error) {
        NSLog(@"❌❌❌ Fail to active audioSession");
        return error;
    }
//    NSLog(@"✅✅✅ initialize audioSession success");
    return nil;
}

- (void)configAudioComponentInstance {
    AudioComponentDescription description;
    description.componentType = kAudioUnitType_Output;          // IO功能的AudioUnit
    description.componentSubType = kAudioUnitSubType_RemoteIO;  // 采集/播放音频
    description.componentManufacturer = kAudioUnitManufacturer_Apple;   // 制造商
    description.componentFlags = 0;
    description.componentFlagsMask = 0;
    // AudioComponentFindNext 函数的结果是对定义音频单元的动态链接库的引用
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &description);
    // 将引用传递给 AudioComponentInstanceNew 函数来实例化音频单元
    OSStatus status = AudioComponentInstanceNew(inputComponent, &_audioUnit);
    if (status != noErr) {
        NSLog(@"❌❌❌ Fail to new component instance ");
    }
}

- (void)configAudioUnitEnableIO {
    uint32_t flag = 1;
    OSStatus status = AudioUnitSetProperty(_audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, K_OUTPUT, &flag, sizeof(flag));
    if (status != noErr) {
        NSLog(@"❌❌❌ Fail to config EnableIO");
    }
}

/**
 *参考
 *https://developer.apple.com/library/archive/documentation/MusicAudio/Conceptual/AudioUnitHostingGuide_iOS/UsingSpecificAudioUnits/UsingSpecificAudioUnits.html#//apple_ref/doc/uid/TP40009492-CH17-SW1
 */
- (void)configAudioStreamFormatWithAudioInfo:(id<JCAudioInfo>)audioInfo {
    AudioStreamBasicDescription audioFormat;
    // 必须初始化为0，保证没有垃圾数据
    memset(&audioFormat, 0, sizeof(AudioStreamBasicDescription));
    // 采样率
    audioFormat.mSampleRate = audioInfo.sampleRate;
    // 音频格式（PCM）
    audioFormat.mFormatID = kAudioFormatLinearPCM;
    // AudioBufferList格式
    audioFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    // 一个packet字节数
    audioFormat.mBytesPerPacket = sizeof(SInt16) * audioInfo.channels;
    // 一个packet中包含多少frame（PCM非压缩数据，每Packet包含一个frame）
    audioFormat.mFramesPerPacket = 1;
    // 每帧字节数
    audioFormat.mBytesPerFrame = sizeof(SInt16) * audioInfo.channels;
    // 声道数
    audioFormat.mChannelsPerFrame = audioInfo.channels;
    // 声道位深
    audioFormat.mBitsPerChannel = sizeof(SInt16) * 8;
    
    OSStatus status = AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, K_OUTPUT, &audioFormat, sizeof(audioFormat));
    [self printASBD:audioFormat];
    if (status != noErr) {
        NSLog(@"❌❌❌ Fail to set ASBD");
    }
}

- (void)printASBD:(AudioStreamBasicDescription)asbd {
    char formatIDString[5];
    UInt32 formatID = CFSwapInt32HostToBig (asbd.mFormatID);
    bcopy (&formatID, formatIDString, 4);
    formatIDString[4] = '\0';
 
    NSLog (@"  Sample Rate:         %10.0f",  asbd.mSampleRate);
    NSLog (@"  Format ID:           %10s",    formatIDString);
    NSLog (@"  Format Flags:        %10X",    asbd.mFormatFlags);
    NSLog (@"  Bytes per Packet:    %10d",    asbd.mBytesPerPacket);
    NSLog (@"  Frames per Packet:   %10d",    asbd.mFramesPerPacket);
    NSLog (@"  Bytes per Frame:     %10d",    asbd.mBytesPerFrame);
    NSLog (@"  Channels per Frame:  %10d",    asbd.mChannelsPerFrame);
    NSLog (@"  Bits per Channel:    %10d",    asbd.mBitsPerChannel);
}

- (void)configAudioRenderCallBack {
    AURenderCallbackStruct renderCallBackStruct;
    renderCallBackStruct.inputProc = renderCallBack;
    renderCallBackStruct.inputProcRefCon = (__bridge void *)self;
    OSStatus status = AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, K_OUTPUT, &renderCallBackStruct, sizeof(renderCallBackStruct));
    if (status != noErr) {
        NSLog(@"❌❌❌ Fail to set render call back");
    }
}

static OSStatus renderCallBack(void *inRefCon,
                               AudioUnitRenderActionFlags *ioActionFlags,
                               const AudioTimeStamp *inTimeStamp,
                               UInt32 inBusNumber,
                               UInt32 inNumberFrames,
                               AudioBufferList * __nullable ioData) {
    JCPlayerAudioRender *audioRender = (__bridge JCPlayerAudioRender *)(inRefCon);
    return [audioRender fillRenderData:ioData numberOfFrames:inNumberFrames];
}

#pragma mark - FillAudioData

- (OSStatus)fillRenderData:(AudioBufferList *)bufferList numberOfFrames:(UInt32)numberOfFrames {
    for (NSUInteger index = 0; index < bufferList->mNumberBuffers; index++) {
        memset(bufferList->mBuffers[index].mData, 0, bufferList->mBuffers[index].mDataByteSize);
    }
    SInt16 buffer[4096] = {0};
    [self.dataSource fillAudioDataWithBuffer:buffer dataByteSize:bufferList->mBuffers[0].mDataByteSize];
    for (NSUInteger index = 0; index < bufferList->mNumberBuffers; index++) {
        memcpy(bufferList->mBuffers[index].mData, buffer, bufferList->mBuffers[0].mDataByteSize);
    }
    return noErr;
}

#pragma mark - JCPlayer

- (void)play {
    AudioOutputUnitStart(_audioUnit);
}

- (void)pause {
    AudioOutputUnitStop(_audioUnit);
}

- (void)stop {
    AudioOutputUnitStop(_audioUnit);
    AudioUnitUninitialize(_audioUnit);
}

@end
