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

@interface ViewController ()
@property (strong, nonatomic) ADAudioUnitPlay *unitPlay;
@property (strong, nonatomic) BaseUnitPlayer  *basePlay;
@property (strong, nonatomic) ADAVAudioPlayer *audioPlayer;
@property (strong, nonatomic) ADAVPlayer *avPlayer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [self playByAVAudioPlayer];
//    [self playByAVPlayer];
    
    [self playPCM];
    
}

- (void)playByAVAudioPlayer
{
    NSString *lpath = [[NSBundle mainBundle] pathForResource:@"test-mp3-1" ofType:@"mp3"];
    [self.audioPlayer initWithPath:lpath];
    [self.audioPlayer play];
}

- (void)playByAVPlayer
{
    // 可以播放远程在线文件
//    NSString *rPath = @"https://img.flypie.net/test-mp3-1.mp3";
    // 本地文件
    NSString *lpath = [[NSBundle mainBundle] pathForResource:@"test-mp3-1" ofType:@"mp3"];
    [self.avPlayer initWithPath:lpath];
    [self.avPlayer play];
}

- (void)playPCM
{
    NSString *l1path = [[NSBundle mainBundle] pathForResource:@"test_441_f32le_2" ofType:@"pcm"];
    
//    self.basePlay = [[BaseUnitPlayer alloc] initWithChannels:2 sampleRate:44100 format:kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsNonInterleaved path:l1path];
//    [self.basePlay play];
    
    self.unitPlay = [[ADAudioUnitPlay alloc] initWithChannels:2 sampleRate:44100 format:kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked path:l1path];
    [self.unitPlay play];
}
@end
