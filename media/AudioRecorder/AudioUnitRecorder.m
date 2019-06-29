//
//  AudioUnitRecorder.m
//  media
//
//  Created by 飞拍科技 on 2019/6/24.
//  Copyright © 2019 飞拍科技. All rights reserved.
//

#import "AudioUnitRecorder.h"
#define BufferList_cache_size (1024*10*5)

@implementation AudioUnitRecorder

- (id)initWithFormatFlags:(AudioFormatFlags)flags
                 channels:(NSInteger)chs
                   format:(AudioFormatID)format
               samplerate:(CGFloat)sampleRate
                     Path:(NSString*)savePath
{
    if (self = [super init]) {
        self.savePath = savePath;
        self.dataWriter = [[AudioDataWriter alloc] init];
        
        self.audioSession = [[ADAudioSession alloc] initWithCategary:AVAudioSessionCategoryRecord channels:chs sampleRate:sampleRate bufferDuration:0.02 formatFlags:flags formatId:format];
        
        // 来电，连上蓝牙，音箱等打断监听
        [self addInterruptListioner];
        
        // 创建AudioComponentDescription描述符
        [self createAudioUnitComponentDescription];
        
        // 创建AudioUnit
        [self createAudioUnit];
        
        // 设置各个AudioUnit的属性
        [self setupAudioUnitsProperty];
        
        // 将各个AudioUnit单元连接起来
        [self makeAudioUnitsConnectionShipness];
        
        // 初始化缓冲器
        /** 遇到问题：采用传统的方式定义变量:AudioBufferList bufferList;然后尝试对bufferList.mBuffers[1]=NULL，会
         *  奔溃
         *  分析原因：因为AudioBufferList默认是只有1个buffer，mBuffers[1]的属性是未初始化的，相当于是NULL，所以这样直接
         *  访问肯定会奔溃
         *  解决方案：采用如下特殊的C语言方式来为AudioBufferList分配内存，这样mBuffers[1]就不会为NULL了
         */
        BOOL isPlanner = [self.audioSession isPlanner];
        _bufferList = (AudioBufferList *)malloc(sizeof(AudioBufferList) + (chs - 1) * sizeof(AudioBuffer));
        
        if (isPlanner) {
            _bufferList->mNumberBuffers = (UInt32)chs;
            for (NSInteger i=0; i<chs; i++) {
                _bufferList->mBuffers[i].mData = malloc(BufferList_cache_size);
                _bufferList->mBuffers[i].mDataByteSize = BufferList_cache_size;
            }
        } else {
            _bufferList->mNumberBuffers = 1;
            _bufferList->mBuffers[0].mData = malloc(BufferList_cache_size);
            _bufferList->mBuffers[0].mDataByteSize = BufferList_cache_size;
        }
    }
    return self;
}

- (void)startRecord
{
    // 删除之前文件
    [self.dataWriter deletePath:_savePath];
    
    OSStatus status = noErr;
    CAShow(_augraph);
    
    status = AUGraphInitialize(_augraph);
    if (status != noErr) {
        NSLog(@"AUGraphInitialize fail %d",status);
    }
    
    status = AUGraphStart(_augraph);
    if (status != noErr) {
        NSLog(@"AUGraphStart fail %d",status);
    }
}

- (void)stopRecord
{
    OSStatus status = noErr;
    status = AUGraphStop(_augraph);
    if (status != noErr) {
        NSLog(@"AUGraphStop fail %d",status);
    }
}

- (void)dealloc
{
    if (_bufferList != NULL) {
        for (int i=0; i<_bufferList->mNumberBuffers; i++) {
            if (_bufferList->mBuffers[i].mData != NULL) {
                free(_bufferList->mBuffers[i].mData);
                _bufferList->mBuffers[i].mData = NULL;
            }
        }
        free(_bufferList);
        _bufferList = NULL;
    }
}

- (void)addInterruptListioner
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

- (void)createAudioUnitComponentDescription
{

    _iodes = [ADUnitTool descriptionWithType:kAudioUnitType_Output subType:kAudioUnitSubType_RemoteIO fucture:kAudioUnitManufacturer_Apple];
    _convertdes = [ADUnitTool descriptionWithType:kAudioUnitType_FormatConverter subType:kAudioUnitSubType_AUConverter fucture:kAudioUnitManufacturer_Apple];
}

- (void)createAudioUnit
{
    OSStatus status = noErr;
    // 1、创建AUGraph
    status = NewAUGraph(&_augraph);
    if (status != noErr) {
        NSLog(@"NewAUGraph fail %x",status);
    }
    
    // 2、根据指定的组件描述符(AudioComponentDescription)创建AUNode,并添加到AUGraph中
    status = AUGraphAddNode(_augraph, &_iodes, &_ioNode);
    if (status != noErr) {
        NSLog(@"AUGraphAddNode _iodes fail %x",status);
    }
    status = AUGraphAddNode(_augraph, &_convertdes, &_convertNode);
    if (status != noErr) {
        NSLog(@"AUGraphAddNode _convertdes fail %x",status);
    }
    
    // 3、打开AUGraph，打开之后才能获取AudioUnit
    status = AUGraphOpen(_augraph);
    if (status != noErr) {
        NSLog(@"AUGraphStart fail %x",status);
    }
    
    // 4、根据AUNode 获取对应AudioUnit；这一步一定要在初始化AUGraph之后;第三个参数传NULL即可
    status = AUGraphNodeInfo(_augraph, _ioNode, NULL, &_ioUnit);
    if (status != noErr) {
        NSLog(@"AUGraphNodeInfo _ioUnit fail %x",status);
    }
    status = AUGraphNodeInfo(_augraph, _convertNode, NULL, &_convertUnit);
    if (status != noErr) {
        NSLog(@"AUGraphNodeInfo _ioUnit fail %x",status);
    }
}

- (void)setupAudioUnitsProperty
{
    // 1、开启麦克风录制功能
    UInt32 flag = 1;
    OSStatus status = noErr;
    // 对于麦克风：第三个参数麦克风为kAudioUnitScope_Input， 第四个参数为1
    // 对于扬声器：第三个参数麦克风为kAudioUnitScope_Output，第四个参数为0
    // 其它参数都一样
    status = AudioUnitSetProperty(_ioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &flag, sizeof(flag));
    if (status != noErr) {
        NSLog(@"AudioUnitSetProperty kAudioUnitScope_Output fail %x",status);
    }
    
    // 2、设置麦克风的输出端参数属性，那么麦克风将按照指定的采样率，格式，存储方式来采集数据然后输出
    AudioFormatFlags flags = self.audioSession.formatFlags;
    CGFloat rate = self.audioSession.currentSampleRate;
    NSInteger chs = self.audioSession.currentChannels;
    AudioStreamBasicDescription des = [ADUnitTool streamDesWithLinearPCMformat:flags sampleRate:rate channels:chs];
    status = AudioUnitSetProperty(_ioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &des, sizeof(des));
    if (status != noErr) {
        NSLog(@"AudioUnitSetProperty _ioUnit kAudioUnitScope_Output fail %x",status);
    }
    
    // 3、设置AUConvert的属性
//    status = AudioUnitSetProperty(_convertUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &des, sizeof(des));
//    if (status != noErr) {
//        NSLog(@"AudioUnitSetProperty _convertUnit kAudioUnitScope_Input fail %x",status);
//    }
//    status = AudioUnitSetProperty(_convertUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &des, sizeof(des));
//    if (status != noErr) {
//        NSLog(@"AudioUnitSetProperty _convertUnit kAudioUnitScope_Input fail %x",status);
//    }
}

- (void)makeAudioUnitsConnectionShipness
{
//    AUGraphConnectNodeInput(_augraph, _ioNode, 1, _convertNode, 0);
    
    AURenderCallbackStruct callback;
    callback.inputProc = InputRenderCallback;
    callback.inputProcRefCon = (__bridge void*)self;
    
    AudioUnitSetProperty(_ioUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Output, 1, &callback, sizeof(callback));
}

/** 作为音频录制输出的回调
 *  1、ioActionFlags 表示目前render operation的阶段
 *  2、inTimeStamp   表示渲染操作的时间 一般12ms调用一次
 *  3、inBusNumber 对应RemoteIO的 BusNumber
 *  4、inNumberFrames 每一次渲染的采样数
 *  5、ioData为NULL
 */
static OSStatus InputRenderCallback(void *inRefCon,
                                    AudioUnitRenderActionFlags *ioActionFlags,
                                    const AudioTimeStamp *inTimeStamp,
                                    UInt32 inBusNumber,
                                    UInt32 inNumberFrames,
                                    AudioBufferList *ioData)
{
    AudioUnitRecorder *player = (__bridge AudioUnitRecorder*)inRefCon;
    UInt32 chs = (UInt32)player.audioSession.currentChannels;
    BOOL isPlanner = [player.audioSession isPlanner];
    int bytesPerChannel = [player.audioSession bytesPerChannel];
    
    NSLog(@"录音 actionflags %u 时间 %f element %d frames %d channel %d planer %d 线程==>%@",*ioActionFlags,inTimeStamp->mSampleTime,inBusNumber,inNumberFrames,chs,isPlanner,[NSThread currentThread]);
    
    // 如果作为音频录制的回调，ioData为NULL
//    NSLog(@"d1 %p d2 %p",ioData->mBuffers[0].mData,ioData->mBuffers[1].mData);
    AudioBufferList *bufferList = player->_bufferList;


    OSStatus status = noErr;
    // 该函数的作用就是将麦克风采集的音频数据根据前面配置的RemoteIO输出数据格式渲染出来，然后放到
    // bufferList缓冲中；那么这里将是PCM格式的原始音频帧
    status = AudioUnitRender(player->_ioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, bufferList);
    if (status != noErr) {
        NSLog(@"AudioUnitRender fail %x",status);
    }
    if (bufferList->mBuffers[0].mData == NULL) {
        return noErr;
    }
    
    /** 遇到问题：如果采集的存储格式为Planner类型，播放不正常
     *  解决方案：ios采集的音频为小端字节序，采集格式为32位，只需要将bufferList中mBuffers对应的数据重新
     *  组合成 左声道右声道....左声道右声道顺序的存储格式即可
     */
    if (isPlanner) {
        // 则需要重新排序一下，将音频数据存储为packet 格式
        int singleChanelLen = bufferList->mBuffers[0].mDataByteSize;
        size_t totalLen = singleChanelLen * chs;
        Byte *buf = (Byte *)malloc(singleChanelLen * chs);
        bzero(buf, totalLen);
        for (int j=0; j<singleChanelLen/bytesPerChannel;j++) {
            for (int i=0; i<chs; i++) {
                Byte *buffer = bufferList->mBuffers[i].mData;
                memcpy(buf+j*chs*bytesPerChannel+bytesPerChannel*i, buffer+j*bytesPerChannel, bytesPerChannel);
            }
        }
        [player.dataWriter writeDataBytes:buf len:totalLen toPath:player.savePath];
        
        // 释放资源
        free(buf);
        buf = NULL;
    } else {
        AudioBuffer buffer = bufferList->mBuffers[0];
        UInt32 bufferLenght = bufferList->mBuffers[0].mDataByteSize;
        [player.dataWriter writeDataBytes:buffer.mData len:bufferLenght toPath:player.savePath];
    }
    
    return status;
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
        // 检测是否能用耳机，如果能用，则切换为耳机模式
        if ([self.audioSession.aSession usingWiredMicrophone]) {
        } else {
            // 检测是否能用蓝牙，如果能用，则用蓝牙进行连接
            if (![self.audioSession.aSession usingBlueTooth]) {
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
            
            break;
        case AVAudioSessionInterruptionTypeEnded:
            
            break;
        default:
            break;
    }
}
@end
