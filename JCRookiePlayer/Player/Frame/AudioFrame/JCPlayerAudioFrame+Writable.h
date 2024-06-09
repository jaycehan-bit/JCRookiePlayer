//
//  JCPlayerAudioFrame+Writable.h
//  JCImage
//
//  Created by jaycehan on 2024/3/15.
//

#import "JCPlayerAudioFrame.h"

NS_ASSUME_NONNULL_BEGIN

@interface JCPlayerAudioFrame (Writable)

@property (nonatomic, assign) CGFloat duration;

@property (nonatomic, assign) CGFloat position;

@property (nonatomic, strong) NSData *sampleData;

@property (nonatomic, assign) NSUInteger channels;

@property (nonatomic, assign) enum AVSampleFormat sampleFormat;

@property (nonatomic, assign) NSUInteger codedSampleBits;

@end

NS_ASSUME_NONNULL_END
