//
//  JCVideoContext.h
//  JCImage
//
//  Created by jaycehan on 2024/3/18.
//

#import <Foundation/Foundation.h>
#import "JCPlayerVideoContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface JCVideoContext : NSObject <JCPlayerVideoContext>

@property (nonatomic, strong) id<JCAudioInfo> audioInfo;

@property (nonatomic, strong) id<JCVideoInfo> videoInfo;

@end

NS_ASSUME_NONNULL_END
