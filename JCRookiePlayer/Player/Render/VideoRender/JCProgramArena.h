//
//  JCProgramArena.h
//  JCImage
//
//  Created by jaycehan on 2023/12/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JCProgramArena : NSObject

@property (nonatomic, copy) CGSize(^renderSize)(void);

- (void)perpare;

- (void)destory;

- (void)renderForFrame:(uint8_t *)frame size:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
