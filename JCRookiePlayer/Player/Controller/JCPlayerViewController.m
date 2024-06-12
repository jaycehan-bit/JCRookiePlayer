//
//  JCPlayerViewController.m
//  JCImage
//
//  Created by jaycehan on 2024/1/15.
//

#import "avformat.h"
#import "JCPlayerAudioRender.h"
#import "JCPlayerRenderView.h"
#import "JCPlayerViewController.h"
#import "JCPlayerSyncController.h"
#import "JCVideoFrame.h"

static const CGFloat JCPlayerRatio = 16 / 9.0;

@interface JCPlayerViewController () <JCPlayerAudioRenderDataSource, JCPlayerDecoderMonitor>

@property (nonatomic, strong) UIBarButtonItem *button;

@property (nonatomic, strong) UIBarButtonItem *nextButton;

@property (nonatomic, strong) JCPlayerRenderView *playerView;

@property (nonatomic, strong) JCPlayerAudioRender *audioRender;

@property (nonatomic, strong) JCPlayerSyncController *syncController;

@end

@implementation JCPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.blackColor;
    [self.view addSubview:self.playerView];
    self.navigationItem.rightBarButtonItems = @[self.nextButton, self.button];
}

- (void)playVideoWithURL:(NSString *)URL {
    if (!URL.length) {
        return;
    }
    [self.syncController registerPlayerStateMonitor:self];
    CFAbsoluteTime beforeOpenTime = CFAbsoluteTimeGetCurrent() * 1000;
    __weak typeof(self) weakSelf = self;
    [self.syncController openFileWithFilePath:URL finishBlock:^(id<JCPlayerVideoContext> videoContext) {
        CFAbsoluteTime afterOpenTime = CFAbsoluteTimeGetCurrent() * 1000;
        NSLog(@"[JCPlayer] Open file time consuming:%f", afterOpenTime - beforeOpenTime);
        if (videoContext) {
            [weakSelf.playerView prepareWithVideoInfo:videoContext.videoInfo];
            [weakSelf.audioRender prepareWithVideoInfo:videoContext.audioInfo];
        }
    }];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
//    self.playerView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.width / JCPlayerRatio);
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self pause];
}

- (void)dealloc {
    NSLog(@"-[JCPlayerViewController dealloc]");
}

#pragma mark - JCPlayerAudioRenderDataSource

- (void)fillAudioDataWithBuffer:(SInt16 *)audioBuffer dataByteSize:(UInt32)byteSize {
    [self.syncController fillAudioRenderDataWithBuffer:audioBuffer byteSize:byteSize];
    id<JCVideoFrame> videoFrame = [self.syncController renderedVideoFrame];
    if (videoFrame) {
        [self.playerView renderVideoFrame:videoFrame];
    }
}

#pragma mark - Init

- (JCPlayerRenderView *)playerView {
    if (!_playerView) {
        _playerView = [[JCPlayerRenderView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.width / JCPlayerRatio)];
        _playerView.backgroundColor = UIColor.blackColor;
    }
    return _playerView;
}

- (JCPlayerAudioRender *)audioRender {
    if (!_audioRender) {
        _audioRender = [[JCPlayerAudioRender alloc] initWithDataSource:self];
    }
    return _audioRender;
}

- (JCPlayerSyncController *)syncController {
    if (!_syncController) {
        _syncController = [[JCPlayerSyncController alloc] init];
    }
    return _syncController;
}

#pragma mark - <JCPlayerDecoderMonitor>

- (void)playerController:(JCPlayerSyncController *)playerController stateChanges:(JCPlayerState)state {
    switch (state) {
        case JCPlayerStatePreparing:
            
            break;
        case JCPlayerStatePrepared:
            [self play];
            break;
        case JCPlayerStateFinished:
            break;
        default:
            break;
    }
}

#pragma mark - DEBUG

- (UIBarButtonItem *)button {
    if (!_button) {
        _button = [[UIBarButtonItem alloc] initWithTitle:@"测试" style:UIBarButtonItemStylePlain target:self action:@selector(debugButtonDidClick)];
        _button.tintColor = UIColor.redColor;
    }
    return _button;
}

- (void)debugButtonDidClick {
    NSString *path = [NSBundle.mainBundle pathForResource:@"ikun.mp4" ofType:nil];
//    NSString *path = [NSBundle.mainBundle pathForResource:@"StreetScenery.mp4" ofType:nil];
    [self playVideoWithURL:path];
}

- (UIBarButtonItem *)nextButton {
    if (!_nextButton) {
        _nextButton = [[UIBarButtonItem alloc] initWithTitle:@"layout" style:UIBarButtonItemStylePlain target:self action:@selector(nextButtonDidClick)];
        _nextButton.tintColor = UIColor.redColor;
    }
    return _nextButton;
}

- (void)nextButtonDidClick {
    CGFloat width = self.view.bounds.size.width;
    if (fabs(width - self.playerView.bounds.size.width) < 1) {
        width *= 0.75;
    }
    self.playerView.frame = CGRectMake(0, 0, width, width / JCPlayerRatio);
}

@end


@implementation JCPlayerViewController (JCPlayer)

- (void)play {
    [self.audioRender play];
}

- (void)pause {
    [self.audioRender pause];
}

- (void)stop {
    [self.audioRender stop];
}

@end
