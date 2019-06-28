//
//  AudioRecorderViewController.m
//  media
//
//  Created by 飞拍科技 on 2019/6/24.
//  Copyright © 2019 飞拍科技. All rights reserved.
//

#import "AudioRecorderViewController.h"
#import "AudioUnitRecorder.h"

@interface AudioRecorderViewController ()
{
    BOOL isRecording;
    BOOL isPlaying;
    NSString *_audioPath;
}
@property (strong, nonatomic) AudioUnitRecorder *audioUnitRecorder;
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
        
    } else {
        isRecording = YES;
        if (self.audioUnitRecorder == nil) {
            self.audioUnitRecorder = [[AudioUnitRecorder alloc] initWithPath:_audioPath];
        }
        
        [self.audioUnitRecorder startRecord];
    }
}

- (void)onTapPlayBtn:(UIButton*)btn
{
    
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
