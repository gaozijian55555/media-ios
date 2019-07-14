//
//  AudioRecorderViewController.m
//  media
//
//  Created by 飞拍科技 on 2019/6/24.
//  Copyright © 2019 飞拍科技. All rights reserved.
//

#import "AudioRecorderViewController.h"
#import "AudioUnitRecorder.h"
#import "AudioUnitGenericOutput.h"
#import "ADAudioUnitPlay.h"
#import "EBDropdownList/EBDropdownListView.h"

@interface AudioRecorderViewController ()
{
    BOOL isRecording;
    BOOL isPlaying;
    NSString *_audioPath;
    
    ADAudioFormatType _formatType;
    BOOL              _planner;
    CGFloat           _sampleRate;
    NSInteger         _channels;
    
    
    EBDropdownListView *_dropdownListView;
    
}
@property (strong, nonatomic) AudioUnitRecorder *audioUnitRecorder;
@property (strong, nonatomic) AudioUnitGenericOutput *audioGenericOutput;
@property (strong, nonatomic) ADAudioUnitPlay *audioUnitPlay;
@property (strong, nonatomic) UIButton *recordBtn;
@property (strong, nonatomic) UIButton *playBtn;

@property (strong, nonatomic) UILabel *statusLabel;
@end

@implementation AudioRecorderViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.recordBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.recordBtn.frame = CGRectMake(150, 200, 100, 50);
    [self.recordBtn setTitle:@"开始" forState:UIControlStateNormal];
    [self.view addSubview:self.recordBtn];
    [self.recordBtn addTarget:self action:@selector(onTapRecordBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(150, 150, 100, 50)];
    self.statusLabel.text = @"";
    [self.view addSubview:self.statusLabel];
    
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
    
    
    EBDropdownListItem *item1 = [[EBDropdownListItem alloc] initWithItem:@"1" itemName:@"录制+存储为PCM"];
    EBDropdownListItem *item2 = [[EBDropdownListItem alloc] initWithItem:@"2" itemName:@"录制+耳返存储为PCM"];
    EBDropdownListItem *item3 = [[EBDropdownListItem alloc] initWithItem:@"3" itemName:@"离线混合音频文件"];
    EBDropdownListItem *item4 = [[EBDropdownListItem alloc] initWithItem:@"4" itemName:@"录制+添加背景音乐"];
    _dropdownListView = [[EBDropdownListView alloc] initWithDataSource:@[item1, item2,item3,item4]];
    _dropdownListView.selectedIndex = 0;
    _dropdownListView.frame = CGRectMake(20, 100, 330, 30);
    [_dropdownListView setViewBorder:0.5 borderColor:[UIColor grayColor] cornerRadius:2];
    [self.view addSubview:_dropdownListView];
    
    __weak typeof(self)weakSelf = self;
    [_dropdownListView setDropdownListViewSelectedBlock:^(EBDropdownListView *dropdownListView) {
        [weakSelf stopRecord];
        [weakSelf stopPlay];
        
        if (dropdownListView.selectedIndex == 0) {
            [weakSelf.recordBtn setTitle:@"开始" forState:UIControlStateNormal];
            weakSelf.recordBtn.hidden = NO;
            [weakSelf.playBtn setTitle:@"开始播放" forState:UIControlStateNormal];
            weakSelf.playBtn.hidden = NO;
        } else if(dropdownListView.selectedIndex == 1){
            [weakSelf.recordBtn setTitle:@"开始" forState:UIControlStateNormal];
            weakSelf.recordBtn.hidden = NO;
            [weakSelf.playBtn setTitle:@"开始播放" forState:UIControlStateNormal];
            weakSelf.playBtn.hidden = NO;
        } else if(dropdownListView.selectedIndex == 2){
            [weakSelf.recordBtn setTitle:@"开始" forState:UIControlStateNormal];
            weakSelf.recordBtn.hidden = NO;
            [weakSelf.playBtn setTitle:@"开始播放" forState:UIControlStateNormal];
            weakSelf.playBtn.hidden = YES;
        } else if(dropdownListView.selectedIndex == 3){
            [weakSelf.recordBtn setTitle:@"开始" forState:UIControlStateNormal];
            weakSelf.recordBtn.hidden = NO;
            [weakSelf.playBtn setTitle:@"开始播放" forState:UIControlStateNormal];
            weakSelf.playBtn.hidden = YES;
        }
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)onTapBackBtn:(UIButton*)btn
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)stopRecord
{
    isRecording = NO;
    if (self.audioUnitRecorder) {
        [self.audioUnitRecorder stopRecord];
        self.audioUnitRecorder = nil;
    }
    [self.recordBtn setTitle:@"开始" forState:UIControlStateNormal];
}
- (void)onTapRecordBtn:(UIButton*)btn
{
    if (isRecording) {  // 正在录音
        isRecording = NO;
        [self stopRecord];
        [self stopPlay];
    } else {
        isRecording = YES;
//        NSString *audioFile = @"test-mp3-1";
//        NSString *audioFile = @"background";
        if (self.audioUnitRecorder != nil) {
            [self.audioUnitRecorder stopRecord];
            self.audioUnitRecorder = nil;
        }
        if (self.audioUnitPlay != nil) {
            [self.audioUnitPlay stop];
            self.audioUnitPlay = nil;
        }
        
        _formatType = ADAudioFormatType32Float;
        _sampleRate = 44100;
        _channels = 2;
        _planner = YES;
        
        NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSInteger _selectIndex = _dropdownListView.selectedIndex;
        if (_selectIndex == 0) {
            // 存储的裸PCM数据
            _audioPath = [path stringByAppendingPathComponent:@"test.PCM"];
            NSLog(@"文件目录 ==>%@",_audioPath);
            
            self.audioUnitRecorder = [[AudioUnitRecorder alloc] initWithFormatType:_formatType planner:_planner channels:_channels samplerate:_sampleRate Path:_audioPath saveFileType:ADAudioFileTypeLPCM];
            self.audioUnitPlay = [[ADAudioUnitPlay alloc] initWithChannels:_channels sampleRate:_sampleRate formatType:_formatType planner:_planner path:_audioPath];
            
            [self.audioUnitRecorder startRecord];
        }
        //            else if(_selectIndex == 1){
        //                self.audioUnitRecorder = [[AudioUnitRecorder alloc] initWithFormatType:_flags planner:_planner channels:_channels samplerate:_sampleRate Path:_audioPath recordAndPlay:YES];
        //                [self.audioUnitRecorder startRecord];
        //            }
        //            else if(_selectIndex == 2){
        //                // 由于AudioFilePlayer无法读取PCM裸数据文件，所以这里用MP3
        //                NSString *file1 = [[NSBundle mainBundle] pathForResource:@"background" ofType:@"mp3"];
        //                NSString *file2 = [[NSBundle mainBundle] pathForResource:@"test-mp3-1" ofType:@"mp3"];
        //                self.audioGenericOutput = [[AudioUnitGenericOutput alloc] initWithPath1:file1 volume:0.1 path2:file2 volume:0.9];
        //                [self.audioGenericOutput setupFormat:ADAudioFormatType16Int audioSaveType:ADAudioSaveTypePacket sampleRate:44100 channels:2 savePath:_audioPath saveFileType:ADAudioFileTypeM4A];
        //                [self.audioGenericOutput start];
        //            }
        //            else if(_selectIndex == 3){
        //                NSString *mixerPath = [[NSBundle mainBundle] pathForResource:audioFile ofType:@"mp3"];
        //                self.audioUnitRecorder = [[AudioUnitRecorder alloc] initWithFormatType:_flags planner:_planner channels:_channels samplerate:_sampleRate Path:_audioPath recordAndPlay:NO mixerPath:mixerPath];
        //                [self.audioUnitRecorder startRecord];
        //            }
        //            else if(_selectIndex == 4){
        //                NSString *mixerPath = [[NSBundle mainBundle] pathForResource:audioFile ofType:@"mp3"];
        //                self.audioUnitRecorder = [[AudioUnitRecorder alloc] initWithFormatType:_flags planner:_planner channels:_channels samplerate:_sampleRate Path:_audioPath recordAndPlay:YES mixerPath:mixerPath];
        //                [self.audioUnitRecorder startRecord];
        //            }
        
        [self.recordBtn setTitle:@"停止" forState:UIControlStateNormal];
    }
}

- (void)onTapPlayBtn:(UIButton*)btn
{
    /** 遇到问题：录制的kAudioFormatFlagIsSignedInteger的音频接着在播放，无法正常播放
     *  解决方案：ios只支持16位整形和32位浮点型的播放，所以所以播放格式设置正确即可
     */
    if (!isPlaying) {
        isPlaying = YES;
        
        [self.audioUnitPlay play];
        [self.playBtn setTitle:@"停止播放" forState:UIControlStateNormal];
    } else {    // 正在播放
        [self stopPlay];
    }
}

- (void)stopPlay
{
    isPlaying = NO;
    [self.audioUnitPlay stop];
    [self.playBtn setTitle:@"开始播放" forState:UIControlStateNormal];
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
