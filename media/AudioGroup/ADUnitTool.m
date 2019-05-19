//
//  ADUnitTool.m
//  media
//
//  Created by Owen on 2019/5/19.
//  Copyright © 2019 Owen. All rights reserved.
//

#import "ADUnitTool.h"

@implementation ADUnitTool
/**
 *  与AudioUnit有关的错误类型枚举定义在AudioToolbox/AUComponent.h文件中
 *  CF_ENUM(OSStatus) {
 *      kAudioUnitErr_InvalidProperty            = -10879,
 *      .......
 *  }
 */
/** AudioUnit的类型,定义在AudioToolbox/AUComponent.h文件中
 *  CF_ENUM(UInt32) {
 kAudioUnitType_Output                    = 'auou',
 kAudioUnitType_MusicDevice               = 'aumu',
 kAudioUnitType_MusicEffect               = 'aumf',
 kAudioUnitType_FormatConverter           = 'aufc',
 kAudioUnitType_Effect                    = 'aufx',
 kAudioUnitType_Mixer                     = 'aumx',
 kAudioUnitType_Panner                    = 'aupn',
 kAudioUnitType_Generator                 = 'augn',
 kAudioUnitType_OfflineEffect             = 'auol',
 kAudioUnitType_MIDIProcessor             = 'aumi'
 };
 *  常用类型如下：
 *  1、kAudioUnitType_Effect;主要用于提供声音特效的处理，包括的子类型有
 *   .均衡效果器:kAudioUnitSubType_NBandEQ，用于为声音的某些频带增强或减弱能量
 *   .压缩效果器:kAudioUnitSubType_DynamicsProcessor,增大或者减少音量
 *   .混响效果器:kAudioUnitSubType_Reverb2,提供混响效果
 *   ....
 *  2、kAudioUnitType_Mixer:提供Mix多路声音功能
 *   .多路混音效果器:kAudioUnitSubType_MultiChannelMixer，可以接受多路音频的输入，然后分别调整每一路音频的增益与开关，并将多路音频合成一路
 *  3、kAudioUnitType_Output:提供音频的录制，播放功能
 *   .录制和播放音频:kAudioUnitSubType_RemoteIO,后面通过AudioUnitSetProperty()方法具体是访问麦克风还是扬声器
 *   .访问音频数据:kAudioUnitSubType_GenericOutput
 *  4、kAudioUnitType_FormatConverter:提供音频格式转化功能,比如采样率转换，声道数转换，采样格式转化，panner到packet转换等等
 *   .kAudioUnitSubType_AUConverter:提供格式转换功能
 *   .kAudioUnitSubType_AudioFilePlayer:直接从文件获取输入音频数据，它具有解码功能
 *   .kAudioUnitSubType_NewTimePitch:变速变调效果器
 */
// 创建指定的类型
+ (AudioComponentDescription)descriptionWithType:(OSType)type subType:(OSType)subType fucture:(OSType)manufuture
{
    AudioComponentDescription acd;
    acd.componentType = type;
    acd.componentSubType = subType;
    acd.componentManufacturer = manufuture;
    return acd;
}

/** AudioStreamBasicDescription详解，它用来描述对应的AudioUnit在处理数据时所需要的数据格式
 *  mSampleRate:音频的采样率，一般有44.1khz，48khz等
 *  mFormatID:编码类型
 *  mFormatFlags:采样格式及存储方式，ios支持两种采样格式(Float，32位，Signed Integer 32)；存储方式就是(Interleaved)Packet和(NonInterleaved)Planner，前者表示每个声道数据交叉存储在AudioBufferList的mBuffers[0]中，后者表示每个声道数据分开存储在mBuffers[i]中
 *  mBitsPerChannel:32(因为ios只有32位的采样格式)*8;一个channel就是个采样
 *  mChannelsPerFrame:声道数
 *  mBytesPerFrame:对于packet包，因为是交叉存储，所以一个frame中有n个channels =mBitsPerChannel*channels
 *  对于planner，因为分开存储在mBuffers[i]中， =mBitsPerChannel
 *  mFramesPerPacket:对于原始数据，一个packet就是包含一个frame；对于压缩数据，一个packet包含多个frame
 *  (不同编码类型，数目不一样，比如aac编码，一个packet包含1024个frame)
 *  mBytesPerPacket:=mBytesPerFrame*mFramesPerPacket
 */
+ (AudioStreamBasicDescription)streamDesWithLinearPCMformat:(AudioFormatFlags)flags sampleRate:(CGFloat)rate channels:(NSInteger)chs
{
    
    // 设置数据格式 ios只支持16位整形和32位浮点型
    UInt32 bytesPerSample = 4;
    if (flags & kAudioFormatFlagIsSignedInteger) {
        bytesPerSample = 2;
    }
    BOOL isPlanner = flags & kAudioFormatFlagIsNonInterleaved;
    
    AudioStreamBasicDescription asbd;
    bzero(&asbd, sizeof(asbd));
    asbd.mSampleRate = rate;   // 采样率
    asbd.mFormatID = kAudioFormatLinearPCM; // 编码格式
    //    odes.mFormatFlags = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;  //采样格式及存储方式
    asbd.mFormatFlags = flags;
    asbd.mBitsPerChannel = 8 * bytesPerSample;
    asbd.mChannelsPerFrame = (UInt32)chs; // 双声道
    if (isPlanner) {
        asbd.mBytesPerFrame = bytesPerSample;//planner存储格式 一个采样字节数
        asbd.mFramesPerPacket = 1;      // 因为前面是kAudioFormatLinearPCM编码格式
        asbd.mBytesPerPacket = asbd.mFramesPerPacket*asbd.mBytesPerFrame;  // 因为一个packet中只有一个frame
    } else {
        asbd.mBytesPerFrame = (UInt32)chs*bytesPerSample;//因为是packet存储格式 声道数*采样字节数
        asbd.mFramesPerPacket = 1;      // 因为前面是kAudioFormatLinearPCM编码格式
        asbd.mBytesPerPacket = asbd.mFramesPerPacket*asbd.mBytesPerFrame;  // 因为一个packet中只有一个frame
    }
    
    return asbd;
}
@end
