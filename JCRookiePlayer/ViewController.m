//
//  ViewController.m
//  JCRookiePlayer
//
//  Created by jaycehan on 2024/5/28.
//

#import "ViewController.h"

static const CGFloat gButtonHeight = 45;
static const CGFloat gButtonWidth = 200;

@interface ViewController ()

@property (nonatomic, strong) UIButton *playButton;

@property (nonatomic, strong) UIButton *recordButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    [self.view addSubview:self.playButton];
    [self.view addSubview:self.recordButton];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.playButton.frame = CGRectMake((self.view.bounds.size.width - gButtonWidth) / 2.0, 150, gButtonWidth, gButtonHeight);
    self.playButton.layer.cornerRadius = 3.5;
    self.recordButton.frame = CGRectMake((self.view.bounds.size.width - gButtonWidth) / 2.0, 250, gButtonWidth, gButtonHeight);
    self.recordButton.layer.cornerRadius = 3.5;
}

- (UIButton *)playButton {
    if (!_playButton) {
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _playButton.backgroundColor = UIColor.systemBlueColor;
        _playButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:14];
        _playButton.titleLabel.text= @"播放";
        _playButton.titleLabel.textColor = UIColor.whiteColor;
    }
    return _playButton;
}

- (UIButton *)recordButton {
    if (!_recordButton) {
        _recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _recordButton.backgroundColor = UIColor.systemGreenColor;
        _recordButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:14];
        _recordButton.titleLabel.text= @"录制";
        _recordButton.titleLabel.textColor = UIColor.whiteColor;
    }
    return _recordButton;
}

@end
