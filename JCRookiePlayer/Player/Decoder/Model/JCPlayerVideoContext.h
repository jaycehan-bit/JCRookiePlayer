//
//  JCPlayerVideoContext.h
//  JCImage
//
//  Created by jaycehan on 2024/3/18.
//

#import <Foundation/Foundation.h>
#import "JCVideoFrame.h"

NS_ASSUME_NONNULL_BEGIN

@protocol JCPlayerVideoContext <NSObject>
/**
 * @brief 音频信息
 */
@property (nonatomic, strong, readonly) id<JCAudioInfo> audioInfo;
/**
 * @brief 视频信息
 */
@property (nonatomic, strong, readonly) id<JCVideoInfo> videoInfo;

@end

NS_ASSUME_NONNULL_END
