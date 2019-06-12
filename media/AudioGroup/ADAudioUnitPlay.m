//
//  ADAudioUnitPlay.m
//  media
//
//  Created by Owen on 2019/5/14.
//  Copyright © 2019 Owen. All rights reserved.
//

#import "ADAudioUnitPlay.h"

@implementation ADAudioUnitPlay
/** 有关结构体
 *  OSStatus;typedef SInt32 OSStatus;noErr;定义在/usr/include/MacTypes.h中
 *  以下结构体都在AudioToolbox下：
 *  AudioUnit;它是一个单元，typedef AudioComponentInstance AudioUnit;
 *  AudioComponentDescription;包括Type，subType，Manufacture(厂商)等等，是构成AudioUnit必不可少的结构体
 *  AUGraph;它是一个桥接器，用来获取AudioUnit;typedef struct OpaqueAUGraph *AUGraph;
 *  AUNode;对于AudioUnit的封装，结合AUGraph获取AudioUnit
 */

-(id)initWithChannels:(NSInteger)chs sampleRate:(CGFloat)rate format:(AudioFormatFlags)iformat path:(NSString *)path
{
    if (self = [super init]) {
        self.aSession = [[ADAudioSession alloc] initWithCategary:AVAudioSessionCategoryPlayback channels:chs sampleRate:rate bufferDuration:0.02 formatFlags:iformat formatId:kAudioFormatLinearPCM];
        
        [self addObservers];
        [self initInputStream:path];
        [self createAudioComponentDesctription];
        [self createAudioUnitByAugraph];
        [self setAudioUnitProperties];
        
    }
    return self;
}

- (void)addObservers
{
    // 添加路由改变时的通知;比如用户插上了耳机，则remoteIO的element0对应的输出硬件由扬声器变为了耳机;策略就是 如果用户连上了蓝牙，则屏蔽手机内置的扬声器
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onNotificationAudioRouteChange:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:nil];
    // 播放过程中收到了被打断的通知处理;比如突然来电，等等。
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onNotificationAudioInterrupted:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:[AVAudioSession sharedInstance]];
}

- (void)createAudioComponentDesctription
{
    // 播放音频描述组件
    _ioDes = [ADUnitTool descriptionWithType:kAudioUnitType_Output subType:kAudioUnitSubType_RemoteIO fucture:kAudioUnitManufacturer_Apple];
    // 格式转换器组件
    _cvtDes = [ADUnitTool descriptionWithType:kAudioUnitType_FormatConverter subType:kAudioUnitSubType_AUConverter fucture:kAudioUnitManufacturer_Apple];
}

- (void)initInputStream:(NSString*)path
{
    // open pcm stream
    NSURL *url = [NSURL fileURLWithPath:path];
    inputSteam = [NSInputStream inputStreamWithURL:url];
    if (!inputSteam) {
        NSLog(@"打开文件失败 %@", url);
    }
    else {
        [inputSteam open];
    }
}

/** 创建 AudioUnit
 *  和通过AUGraph创建；
*/
- (void)createAudioUnitByAugraph
{
    OSStatus status = noErr;
    //1、创建AUGraph
    status = NewAUGraph(&_aGraph);
    if (status != noErr) {
        NSLog(@"create AUGraph fail %d",status);
    }
    
    //2.2 将指定的组件描述创建AUNode并添加到AUGraph中
    status = AUGraphAddNode(_aGraph, &_ioDes, &_ioNode);
    if (status != noErr) {
        NSLog(@"AUGraphAddNode fail _ioDes %d",status);
    }
    status = AUGraphAddNode(_aGraph, &_cvtDes, &_cvtNode);
    if (status != noErr) {
        NSLog(@"AUGraphAddNode fail _cvtDes %d",status);
    }
    
    // 3、打开AUGraph(即初始化了AUGraph)
    status = AUGraphOpen(_aGraph);
    if (status != noErr) {
        NSLog(@"AUGraphOpen fail %d",status);
    }
    
    // 4、打开了AUGraph之后才能获取指定的AudioUnit
    status = AUGraphNodeInfo(_aGraph, _ioNode, NULL, &_ioUnit);
    if (status != noErr) {
        NSLog(@"AUGraphNodeInfo fail %d",status);
    }
    status = AUGraphNodeInfo(_aGraph, _cvtNode, NULL, &_cvtUnit);
    if (status != noErr) {
        NSLog(@"AUGraphNodeInfo fail %d",status);
    }
    
}

/** 设置AudioUnit属性
 *  1、通过AudioUnitSetProperty
 *  2、关于remoteIO的element，扬声器对应的AudioUnitElement值为0，app能控制的AudioUnitScope值为kAudioUnitScope_Input；麦克风对应的AudioUnitElement值为1
 *  app能控制的udioUnitScope值为kAudioUnitScope_Output
 */
- (void)setAudioUnitProperties
{
    // 开启扬声器的播放功能；注：对于扬声器默认是开启的，对于麦克风则默认是关闭的
    uint32_t flag = 1;// 1代表开启，0代表关闭
    OSStatus status = AudioUnitSetProperty(_ioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &flag, sizeof(flag));
    if (status != noErr) {
        NSLog(@"AudioUnitSetProperty fail %d",status);
    }
    
    AudioFormatFlags flags = self.aSession.formatFlags;
    CGFloat rate = self.aSession.currentSampleRate;
    NSInteger chs = self.aSession.currentChannels;
    //输入给扬声器的音频数据格式
    AudioStreamBasicDescription odes = [ADUnitTool streamDesWithLinearPCMformat:kAudioFormatFlagIsFloat|kAudioFormatFlagIsNonInterleaved sampleRate:rate channels:chs];
    // PCM文件的音频的数据格式
    AudioStreamBasicDescription cvtInDes = [ADUnitTool streamDesWithLinearPCMformat:flags sampleRate:rate channels:chs];
    
    // 设置扬声器的输入音频数据格式
    status = AudioUnitSetProperty(_ioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &odes, sizeof(odes));
    if (status != noErr) {
        NSLog(@"AudioUnitSetProperty io fail %d",status);
    }
    
    // 设置格式转换器的输入输出音频数据格式;对于格式转换器AudioUnit 他的AudioUnitElement只有一个 element0
    status = AudioUnitSetProperty(_cvtUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &cvtInDes, sizeof(cvtInDes));
    if (status != noErr) {
        NSLog(@"AudioUnitSetProperty convert in fail %d",status);
    }
    status = AudioUnitSetProperty(_cvtUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &odes, sizeof(odes));
    if (status != noErr) {
        NSLog(@"AudioUnitSetProperty convert ou fail %d",status);
    }
    
    /** 构建连接
     *  只有构建连接之后才有一个完整的数据驱动链。如下将构成链条如下：
     *  _cvtUnit通过回调向文件要数据，得到数据后进行格式转换，将输出作为输入数据输送给_ioUnit，然后_ioUnit播放数据
     */
    status = AUGraphConnectNodeInput(_aGraph, _cvtNode, 0, _ioNode, 0);
    if (status != noErr) {
        NSLog(@"AUGraphConnectNodeInput fail %d",status);
    }
    AURenderCallbackStruct callback;
    callback.inputProc = InputRenderCallback;
    callback.inputProcRefCon = (__bridge void*)self;
    status = AudioUnitSetProperty(_cvtUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &callback, sizeof(callback));
    if (status != noErr) {
        NSLog(@"AudioUnitSetProperty fail %d",status);
    }
}

- (void)play
{
    OSStatus stauts;
    CAShow(_aGraph);
    
    // 7、初始化AUGraph,初始化之后才能正常启动播放
    stauts = AUGraphInitialize(_aGraph);
    if (stauts != noErr) {
        NSLog(@"AUGraphInitialize fail %d",stauts);
    }
    stauts = AUGraphStart(_aGraph);
    if (stauts != noErr) {
        NSLog(@"AUGraphStart fail %d",stauts);
    }
}

- (void)stop
{
    OSStatus status;
    status = AUGraphStop(_aGraph);
    if (status != noErr) {
        NSLog(@"AUGraphStop fail %d",status);
    }
}

- (void)destroyAudioUnit
{
    if (_aGraph) {
        AUGraphStop(_aGraph);
        AUGraphUninitialize(_aGraph);
        AUGraphClose(_aGraph);
        AUGraphRemoveNode(_aGraph, _ioNode);
        DisposeAUGraph(_aGraph);
        _ioUnit = NULL;
        _ioNode = 0;
        _aGraph = NULL;
    } else {
        AudioOutputUnitStop(_ioUnit);
    }
    
}

#pragma mark 播放声音过程中收到了路由改变通知处理
- (void)onNotificationAudioRouteChange:(NSNotification *)sender
{
    [self adjustOnRouteChange];
}

- (void)adjustOnRouteChange
{
    AVAudioSessionRouteDescription *currentRoute = [[AVAudioSession sharedInstance] currentRoute];
    if (currentRoute) {
        if ([self.aSession.aSession usingWiredMicrophone]) {
        } else {
            if (![self.aSession.aSession usingBlueTooth]) {
                [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
            }
        }
    }
}

#pragma mark 播放声音过程中收到了路由改变通知处理
- (void)onNotificationAudioInterrupted:(NSNotification *)sender {
    AVAudioSessionInterruptionType interruptionType = [[[sender userInfo] objectForKey:AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    switch (interruptionType) {
        case AVAudioSessionInterruptionTypeBegan:
            [self stop];
            break;
        case AVAudioSessionInterruptionTypeEnded:
            [self play];
            break;
        default:
            break;
    }
}

/** AudioBufferList详解
 *  struct AudioBufferList
 *  {
 *      UInt32      mNumberBuffers; // 填写channels个数
 *      AudioBuffer mBuffers[1]; // 这里的定义等价于 AudioBuffer *mBuffers,所以它的元素个数是不固定的,元素个数由mNumberBuffers决定;
 *      对于packet数据,各个声道数据依次存储在mBuffers[0]中,对于planner格式,每个声道数据分别存储在mBuffers[0],...,mBuffers[i]中
 *      对于packet数据,AudioBuffer中mNumberChannels数目等于channels数目，对于planner则始终等于1
 *      ......
 *  };
 *  typedef struct AudioBufferList  AudioBufferList;
 */
// 大概每10ms 扬声器会向app要一次数据
static OSStatus InputRenderCallback(void *inRefCon,
                                    AudioUnitRenderActionFlags *ioActionFlags,
                                    const AudioTimeStamp *inTimeStamp,
                                    UInt32 inBusNumber,
                                    UInt32 inNumberFrames,
                                    AudioBufferList *ioData)
{
    ADAudioUnitPlay *player = (__bridge id)inRefCon;
    NSLog(@"d1 %p d2 %p",ioData->mBuffers[0].mData,ioData->mBuffers[1].mData);
    for (int iBuffer=0; iBuffer < ioData->mNumberBuffers; ++iBuffer) {
        ioData->mBuffers[iBuffer].mDataByteSize = (UInt32)[player->inputSteam read:ioData->mBuffers[iBuffer].mData maxLength:(NSInteger)ioData->mBuffers[iBuffer].mDataByteSize];
        NSLog(@"buffer %d out size: %d",iBuffer, ioData->mBuffers[iBuffer].mDataByteSize);
        NSLog(@"数据 %@",[NSData dataWithBytes:ioData->mBuffers[0].mData length:(NSInteger)ioData->mBuffers[iBuffer].mDataByteSize]);
    }
    
    return noErr;
}
@end
