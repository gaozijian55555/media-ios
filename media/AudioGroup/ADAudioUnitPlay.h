//
//  ADAudioUnitPlay.h
//  media
//
//  Created by Owen on 2019/5/14.
//  Copyright © 2019 Owen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioCommon.h"

/** AudioUnit实现音频播放
 *  1、需引入头文件 #import<AVFoundation/AVFoundation.h>;#import <AudioToolbox/AudioToolbox.h>
 */
@interface ADAudioUnitPlay : NSObject
{
    AUGraph   _aGraph;
    
    // 小型结构体，不占用资源
    // remote IO描述体
    AudioComponentDescription _ioDes;
    AUNode    _ioNode;
    AudioUnit _ioUnit;
    
    // 格式转换器描述体
    AudioComponentDescription _cvtDes;
    AUNode    _cvtNode;
    AudioUnit _cvtUnit;
    
    // 输送给扬声器的结构体，里面填装的音频数据
    NSInputStream *inputSteam;
}
@property (strong, nonatomic) ADAudioSession *aSession;

-(id)initWithChannels:(NSInteger)chs sampleRate:(CGFloat)rate format:(AudioFormatFlags)iformat path:(NSString*)path;

// 可以以planner格式播放音频。
- (void)play;
- (void)stop;

@end
