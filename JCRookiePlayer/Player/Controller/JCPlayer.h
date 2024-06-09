//
//  JCPlayer.h
//  JCImage
//
//  Created by jaycehan on 2024/1/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol JCPlayer <NSObject>

/**!
 @brief 开始播放
*/
- (void)play;

/**!
 @brief 暂停播放
*/
- (void)pause;

/**!
 @brief 停止播放
*/
- (void)stop;

@end

NS_ASSUME_NONNULL_END
