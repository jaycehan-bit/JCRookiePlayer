//
//  JCPlayerViewController.h
//  JCImage
//
//  Created by jaycehan on 2024/1/15.
//

#import <UIKit/UIKit.h>
#import "JCPlayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface JCPlayerViewController : UIViewController

- (void)playVideoWithURL:(NSString *)URL;

@end

@interface JCPlayerViewController (JCPlayer) <JCPlayer>

@end

NS_ASSUME_NONNULL_END
