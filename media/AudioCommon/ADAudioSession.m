//
//  ADAudioSession.m
//  media
//
//  Created by Owen on 2019/5/19.
//  Copyright © 2019 Owen. All rights reserved.
//

#import "ADAudioSession.h"
// 三种不同音频播放延迟
const NSTimeInterval AUSAudioSessionDelay_Background = 0.0929;
const NSTimeInterval AUSAudioSessionDelay_Default = 0.0232;
const NSTimeInterval AUSAudioSessionDelay_Low = 0.0058;

@implementation ADAudioSession
- (instancetype)init
{
    return [self initWithCategary:AVAudioSessionCategoryPlayback channels:2 sampleRate:44100 bufferDuration:AUSAudioSessionDelay_Low*4 formatFlags:kAudioFormatFlagIsPacked formatId:kAudioFormatLinearPCM];
}

-(instancetype)initWithCategary:(AVAudioSessionCategory)category channels:(NSInteger)chs sampleRate:(double)rate bufferDuration:(NSTimeInterval)duration formatFlags:(AudioFormatFlags)flags formatId:(AudioFormatID)formatId
{
    if (self = [super init]) {
        /** AVAudioSession 是一个单例，表示一个音频会话，不管录制音频还是播放音频都需要这样一个音频会话，它表示要播放和要录制音频的属性，比如：
         *  采样率，采样格式，存储方式，编码方式，缓冲区延迟等等。
         */
        self.currentSampleRate = rate;
        // 要采集或者播放音频的声道数
        self.currentChannels = chs;
        /** 音频采样数据的存储格式，比如
         *  kAudioFormatFlagIsSignedInteger：表示每一个采样数据是由32位整数来表示
         *  kAudioFormatFlagIsFloat：表示每一个采样数据由32位浮点数来表示
         *  kAudioFormatFlagIsPacked：每个声道数据交叉存储在AudioBufferList的mBuffers[0]中,如：左声道右声道左声道右声道....
         *  kAudioFormatFlagIsNonInterleaved：表示每个声道数据分开存储在mBuffers[i]中如：
         *  mBuffers[0],左声道左声道左声道左声道
         *  mBuffers[1],右声道右声道右声道右声道
         */
        self.formatFlags = flags;
        // 表示音频的编码格式 如kAudioFormatLinearPCM 表示音频为linearPCM编码
        self.formatId = formatId;
        
        // 1、创建一个音频会话 它是单例；AVAudioSession 在AVFoundation/AVFAudio/AVAudioSession.h中定义
        _aSession = [AVAudioSession sharedInstance];
        
        //  2、======配置音频会话 ======//
        /** 配置使用的音频硬件:
         *  AVAudioSessionCategoryPlayback:只是进行音频的播放(只使用听的硬件，比如手机内置喇叭，或者通过耳机)
         *  AVAudioSessionCategoryRecord:只是采集音频(只录，比如手机内置麦克风)
         *  AVAudioSessionCategoryPlayAndRecord:一边采集一遍播放(听和录同时用)
         */
        [_aSession setCategory:category error:nil];
        
        // 设置采样率，不管是播放还是录制声音 都需要设置采样率
        [_aSession setPreferredSampleRate:rate error:nil];
        
        // 设置I/O的Buffer，数值越小说明缓存的数据越小，延迟也就越低；这里意思就是麦克风采集声音时只缓存20ms的数据
//        [_aSession setPreferredIOBufferDuration:duration error:nil];
        
        // 激活会话
        [_aSession setActive:YES error:nil];
    }
    
    return self;
}

- (BOOL)isPlanner
{
    return self.formatFlags & kAudioFormatFlagIsNonInterleaved;
}

-(int)bytesPerChannel
{
    return 4;
}
@end
