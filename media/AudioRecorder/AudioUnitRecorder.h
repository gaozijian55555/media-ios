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

/** 本类设计的目的需求为
 *  1、实现音频录制
 *  2、将录制的音频数据编码然后保存到文件中
 */
@interface AudioUnitRecorder : NSObject
{
    AUGraph _augraph;
    
    // remoteIO Unit 用于麦克风
    AudioComponentDescription   _iodes;
    AUNode                      _ioNode;
    AudioUnit                   _ioUnit;
    
    // 格式转化 Unit
    AudioComponentDescription   _convertdes;
    AUNode                      _convertNode;
    AudioUnit                   _convertUnit;
    
    AudioBufferList *           _bufferList;
}
@property (strong, nonatomic)ADAudioSession  *audioSession;
@property (strong, nonatomic)AudioDataWriter *dataWriter;
@property (strong, nonatomic)NSString *savePath;

- (id)initWithFormatFlags:(AudioFormatFlags)flags
                 channels:(NSInteger)chs
                   format:(AudioFormatID)format
               samplerate:(CGFloat)sampleRate
                     Path:(NSString*)savePath;

- (void)startRecord;
- (void)stopRecord;

@end
