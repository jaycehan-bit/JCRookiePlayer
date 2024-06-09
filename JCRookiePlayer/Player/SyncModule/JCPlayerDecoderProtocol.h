//
//  JCPlayerDecoderProtocol.h
//  JCImage
//
//  Created by jaycehan on 2024/3/29.
//

#import <Foundation/Foundation.h>
@class JCPlayerSyncController;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, JCPlayerState) {
    JCPlayerStatePreparing = 1,
    JCPlayerStatePrepared = 2,
};

@protocol JCPlayerDecoderMonitor <NSObject>

- (void)playerController:(JCPlayerSyncController *)playerController stateChanges:(JCPlayerState)state;

@end

NS_ASSUME_NONNULL_END
