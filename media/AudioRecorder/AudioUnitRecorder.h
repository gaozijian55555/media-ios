//
//  AudioUnitRecorder.h
//  media
//
//  Created by 飞拍科技 on 2019/6/24.
//  Copyright © 2019 飞拍科技. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioCommon.h"
#import "AudioDataWriter.h"
#import "ADExtAudioFile.h"

/** 本类设计的目的需求为
 *  1、实现音频录制
 *  2、将录制的音频数据编码然后保存到文件中
 */
@interface AudioUnitRecorder : NSObject
{
    AUGraph _augraph;
    
    // remoteIO Unit 用于麦克风和扬声器
    AudioComponentDescription   _iodes;
    AUNode                      _ioNode;
    AudioUnit                   _ioUnit;
    
    // 格式转化 Unit
    AudioComponentDescription   _convertdes;
    AUNode                      _convertNode;
    AudioUnit                   _convertUnit;
    
    // 混音器
    AudioComponentDescription   _mixerDes;
    AUNode                      _mixerNode;
    AudioUnit                   _mixerUnit;
    
    AudioBufferList *           _bufferList;
    
    // 是否开启了混音
    BOOL _enableMixer;
    NSString *_mixerPath;
    AudioStreamBasicDescription _mixerStreamDesForInput;    // 混音器的输入数据格式
    AudioStreamBasicDescription _mixerStreamDesForOutput;    // 混音器的输出数据格式
    
    // 是否边录边播
    BOOL _isEnablePlayWhenRecord;
}
@property (strong, nonatomic)ADAudioSession  *audioSession;
@property (strong, nonatomic)AudioDataWriter *dataWriter;
@property (strong, nonatomic)NSString *savePath;
@property (strong, nonatomic)ADExtAudioFile *dataReader;
/** 实现录音功能，这里channels，samplerate，代表了录制的音频的参数，savePath表示录制音频存储的路径
 */
- (id)initWithFormatType:(ADAudioFormatType)formatType
                 planner:(BOOL)planner
                channels:(NSInteger)chs
              samplerate:(CGFloat)sampleRate
                    Path:(NSString*)savePath;

/** 实现边录边播的耳返监听功能
 *  在麦克风录制声音的同时又将声音从扬声器播放出来，此功能称为边录边播。不过要注意的是，此功能得带上耳机才有很好的体验效果。否则
 *  像拖拉机一样
 */
- (id)initWithFormatType:(ADAudioFormatType)formatType
                 planner:(BOOL)planner
                channels:(NSInteger)chs
              samplerate:(CGFloat)sampleRate
                    Path:(NSString*)savePath
           recordAndPlay:(BOOL)yesOrnot;

// 开启混音，那么将录音和这里指定的音频文件声音进行混合，然后输出;默认关闭混音；这里实现录制声音和指定文件的声音进行混合
// 备注：这里只考虑要混合的音频文件和录制的音轨是统一的声道数，采样率，采样格式的情况,所以这里传入音频文件时要注意
// path存在就会开启混音
- (id)initWithFormatType:(ADAudioFormatType)formatType
                 planner:(BOOL)planner
                channels:(NSInteger)chs
              samplerate:(CGFloat)sampleRate
                    Path:(NSString*)savePath
           recordAndPlay:(BOOL)yesOrnot
               mixerPath:(NSString*)path;


- (void)startRecord;
- (void)stopRecord;

@end
