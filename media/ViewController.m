//
//  ViewController.m
//  media
//
//  Created by Owen on 2019/5/14.
//  Copyright © 2019 Owen. All rights reserved.
//

#import "ViewController.h"
#import "ADAudioUnitPlay.h"
#import "ADAVPlayer.h"
#import "ADAVAudioPlayer.h"
#import "BaseUnitPlayer.h"
#import "YuvPlayer.h"
#import "VideoFileSource.h"

@interface ViewController ()
@property (strong, nonatomic) ADAudioUnitPlay *unitPlay;
@property (strong, nonatomic) BaseUnitPlayer  *basePlay;
@property (strong, nonatomic) ADAVAudioPlayer *audioPlayer;
@property (strong, nonatomic) ADAVPlayer *avPlayer;

@property(nonatomic,strong)VideoFileSource *source;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [self playByAVAudioPlayer];
//    [self playByAVPlayer];
    
//    [self playPCM];
    
    
    // ======= 播放yuv视频  =========== //
    NSString *lpath = [[NSBundle mainBundle] pathForResource:@"test-420P-320x160" ofType:@"yuv"];
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(1000, 200, 320, 160)];
    view.backgroundColor = [UIColor redColor];
    [self.view addSubview:view];
    // 初始化播放器
    YuvPlayer *player = [YuvPlayer shareInstance];
    [player setVideoView:view];
    [player play];
    // 初始化视频源
    NSURL *fileUrl = [NSURL fileURLWithPath:lpath];
    self.source = [[VideoFileSource alloc] initWithFileUrl:fileUrl];
    self.source.delegate = player;
    [self.source setVideoWidth:640 height:360];
    [self.source beginPullVideo];
    // ======= 播放yuv视频  =========== //
}

- (void)playByAVAudioPlayer
{
    self.audioPlayer = [[ADAVAudioPlayer alloc] init];
    NSString *lpath = [[NSBundle mainBundle] pathForResource:@"test-mp3-1" ofType:@"mp3"];
    [self.audioPlayer initWithPath:lpath];
    [self.audioPlayer play];
}

- (void)playByAVPlayer
{
    self.avPlayer = [[ADAVPlayer alloc] init];
    
    // 注意如果是本地的这里要用fileURLWithxxx；远程的则用urlWithxxx，否则url协议解析会出错
    // 可以播放远程在线文件
    NSString *rPath = @"https://img.flypie.net/test-mp3-1.mp3";
    NSURL *remoteUrl = [NSURL URLWithString:rPath];
    
    // 本地文件
    NSString *lpath = [[NSBundle mainBundle] pathForResource:@"test-mp3-1" ofType:@"mp3"];
    NSURL *localUrl = [NSURL URLWithString:lpath];
    
    [self.avPlayer initWithURL:remoteUrl];
    [self.avPlayer play];
}

- (void)playPCM
{
//    NSString *l1path = [[NSBundle mainBundle] pathForResource:@"test_441_f32le_2" ofType:@"pcm"];
    NSString *l1path = [[NSBundle mainBundle] pathForResource:@"test_441_s16le_2" ofType:@"amr"];
    
//    self.basePlay = [[BaseUnitPlayer alloc] initWithChannels:2 sampleRate:44100 format:kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsNonInterleaved path:l1path];
//    [self.basePlay play];
    
//    self.unitPlay = [[ADAudioUnitPlay alloc] initWithChannels:2 sampleRate:44100 format:kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked path:l1path];
    self.unitPlay = [[ADAudioUnitPlay alloc] initWithChannels:2 sampleRate:44100 format:kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked path:l1path];
    [self.unitPlay play];
}
@end
