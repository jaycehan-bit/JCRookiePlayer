//
//  JCPlayerAudioRender.h
//  JCImage
//
//  Created by jaycehan on 2024/3/18.
//

#import <Foundation/Foundation.h>
#import "JCPlayer.h"
#import "JCVideoFrame.h"

NS_ASSUME_NONNULL_BEGIN

@protocol JCPlayerAudioRenderDataSource <NSObject>

- (void)fillAudioDataWithBuffer:(SInt16 *)audioBuffer dataByteSize:(UInt32)byteSize;

@end

@interface JCPlayerAudioRender : NSObject <JCPlayer>

- (instancetype)initWithDataSource:(id<JCPlayerAudioRenderDataSource>)dataSource;

- (void)prepareWithVideoInfo:(id<JCAudioInfo>)videoInfo;

@end

NS_ASSUME_NONNULL_END
