//
//  AudioRecorderViewController.m
//  media
//
//  Created by 飞拍科技 on 2019/6/24.
//  Copyright © 2019 飞拍科技. All rights reserved.
//

#import "AudioRecorderViewController.h"
#import "AudioUnitRecorder.h"
#import "ADAudioUnitPlay.h"

@interface AudioRecorderViewController ()
{
    BOOL isRecording;
    BOOL isPlaying;
    NSString *_audioPath;
    
    ADAudioFormatType _flags;
    BOOL              _planner;
    CGFloat           _sampleRate;
    NSInteger         _channels;
    
}
@property (strong, nonatomic) AudioUnitRecorder *audioUnitRecorder;
@property (strong, nonatomic) ADAudioUnitPlay *audioUnitPlay;
@property (strong, nonatomic) UIButton *recordBtn;
@property (strong, nonatomic) UIButton *playBtn;
@end

@implementation AudioRecorderViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    _audioPath = [path stringByAppendingPathComponent:@"test.PCM"];
    NSLog(@"文件目录 ==>%@",_audioPath);
    // 16位整形
    _flags = ADAudioFormatType32Float;
    _sampleRate = 44100;
    _channels = 2;
    _planner = YES;
    
    self.recordBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.recordBtn.frame = CGRectMake(150, 200, 100, 50);
    [self.recordBtn setTitle:@"开始录音" forState:UIControlStateNormal];
    [self.view addSubview:self.recordBtn];
    [self.recordBtn addTarget:self action:@selector(onTapRecordBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    self.playBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.playBtn.frame = CGRectMake(150, 270,100, 50);
    [self.playBtn setTitle:@"播放录音" forState:UIControlStateNormal];
    [self.view addSubview:self.playBtn];
    [self.playBtn addTarget:self action:@selector(onTapPlayBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    backBtn.frame = CGRectMake(20, 50, 50, 50);
    [backBtn setTitle:@"返回" forState:UIControlStateNormal];
    [self.view addSubview:backBtn];
    [backBtn addTarget:self action:@selector(onTapBackBtn:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)onTapBackBtn:(UIButton*)btn
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onTapRecordBtn:(UIButton*)btn
{
    if (isRecording) {  // 正在录音
        isRecording = NO;
        [self.audioUnitRecorder stopRecord];
        [self.recordBtn setTitle:@"开始录音" forState:UIControlStateNormal];
        
    } else {
        isRecording = YES;
        if (self.audioUnitRecorder == nil) {
            self.audioUnitRecorder = [[AudioUnitRecorder alloc] initWithFormatType:_flags planner:_planner channels:_channels samplerate:_sampleRate Path:_audioPath];
        }
        
        [self.audioUnitRecorder startRecord];
        
        [self.recordBtn setTitle:@"停止录音" forState:UIControlStateNormal];
    }
}

- (void)onTapPlayBtn:(UIButton*)btn
{
    /** 遇到问题：录制的kAudioFormatFlagIsSignedInteger的音频接着在播放，无法正常播放
     *  解决方案：ios只支持16位整形和32位浮点型的播放，所以所以播放格式设置正确即可
     */
    if (!isPlaying) {
        isPlaying = YES;
        if (self.audioUnitPlay == nil) {
            self.audioUnitPlay = [[ADAudioUnitPlay alloc] initWithChannels:_channels sampleRate:_sampleRate formatType:_flags planner:_planner path:_audioPath];
        }
        [self.audioUnitPlay play];
        [self.playBtn setTitle:@"停止播放" forState:UIControlStateNormal];
    } else {    // 正在播放
        isPlaying = NO;
        [self.audioUnitPlay stop];
        [self.playBtn setTitle:@"开始播放" forState:UIControlStateNormal];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
