//
//  JCPlayerRenderView.h
//  JCImage
//
//  Created by jaycehan on 2024/2/5.
//

#import <UIKit/UIKit.h>
#import "JCVideoFrame.h"

NS_ASSUME_NONNULL_BEGIN

@interface JCPlayerRenderView : UIView

- (void)prepareWithVideoInfo:(id<JCVideoInfo>)videoInfo;

- (void)renderVideoFrame:(id<JCVideoFrame>)videoFrame;

@end

NS_ASSUME_NONNULL_END
