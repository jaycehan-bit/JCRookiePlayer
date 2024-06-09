//
//  JCPlayerSyncModule.h
//  JCImage
//
//  Created by jaycehan on 2024/3/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol JCPlayerSyncModule <NSObject>

- (NSUInteger)fillAudioFrameData:(SInt16 *)sampleBuffer numOfFrames:(NSUInteger)numOfFrames numOfChannels:(NSUInteger)numOfChannels;

@end

NS_ASSUME_NONNULL_END
