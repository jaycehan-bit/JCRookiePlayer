//
//  JCPlayerVideoFrame+Writable.h
//  JCImage
//
//  Created by jaycehan on 2024/3/15.
//

#import "JCPlayerVideoFrame.h"

NS_ASSUME_NONNULL_BEGIN

@interface JCPlayerVideoFrame (Writable)

@property (nonatomic, assign) CGFloat duration;

@property (nonatomic, assign) CGFloat position;

@property (nonatomic, assign) NSUInteger height;

@property (nonatomic, assign) NSUInteger width;

@property (nonatomic, strong) NSData *luminance;

@property (nonatomic, strong) NSData *chrominance;

@property (nonatomic, strong) NSData *chroma;

@end

NS_ASSUME_NONNULL_END
