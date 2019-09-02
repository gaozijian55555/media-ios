//
//  ADVTEncoder.m
//  media
//
//  Created by 飞拍科技 on 2019/8/9.
//  Copyright © 2019 飞拍科技. All rights reserved.
//

#import "ADVTEncoder.h"

@implementation ADVTEncoder
{
    VTCompressionSessionRef _encodeSession;
    int64_t                 _frameId;       // 视频帧的序号
    int32_t                 _width,_height; // 要编码的视频的宽和高
}

/** H264编码 基础知识
 *  1、H264采用的核心算法是帧内压缩和帧间压缩，帧内压缩是生成I帧的算法，帧间压缩是生成B帧和P帧的算法。
 *  2、H264原始码流是由一个接一个的NALU（Nal Unit）组成的，NALU = 开始码 + NALU类型 + 视频数据，它可以直接播放
 *   开始码:必须是"00 00 00 01" 或"00 00 01"
 * NALU类型:一般只用到1、5、7、8这4个类型,类型为5表示这是一个I帧，I帧前面必须有SPS和PPS数据，也就是类型为7和8，类型为1表示这是一个P帧或B帧。
 *  h264原始码流一般按照如下顺序：NALU(SPS)+NALU(PPS)+NALU(Idr帧)+NALU(P帧)+NALU(P/B帧)+..+NALU(SPS)+NALU(PPS)NALU(I帧)+.....
 */
- (void)initVideoToolbox
{
    /** 创建编码器对象 VTCompressionSessionRef
     *  参数1：创建对象内存使用的内存分配器，NULL代表使用默认分配器kCFAllocatorDefault
     *  参数2/3：要编码的视频帧的宽和高；单位像素
     *  参数4：使用的编码方式 比如H264(kCMVideoCodecType_H264)
     *  参数5：设置编码方式相关的参数，比如H264编码所需的参数；CFDictionaryRef类型，NULL，则默认值;也可以
     *  通过VTSessionSetProperty()函数设置
     *  参数6：设置原始视频数据缓存的方式，CFDictionaryRef类型，NULL则代表使用默认值
     *  参数7：设置编码数据的内存分配器及其它保存方式，CFAllocatorRef类型，NULL则使用默认值
     *  参数8：设置编码数据输出回调函数
     *  参数9：设置传入给该回调函数的参数；void*类型
     *  参数10：要创建的VTCompressionSessionRef对象
     */
    /** 遇到问题：返回-12902错误
     *  分析问题：在VTErrors.h中查看错误说明，意思参数错误，经检查是_width和_height没有指定具体的值
     *  解决问题：给_width和_height赋上具体的值
     */
    OSStatus status = VTCompressionSessionCreate(NULL, _width, _height, kCMVideoCodecType_H264, NULL, NULL, NULL, didCompressH264, (__bridge void *)self, &_encodeSession);
    if (status != noErr) {
        NSLog(@"VTCompressionSessionCreate fail %d",status);
        return;
    }
    
    /** VTSessionSetProperty()函数既可以设置编码相关属性，又可以设置解码相关属性
     *  对于H264编码来说，以下属性是必须的
     *  1、编码效率级别:kVTCompressionPropertyKey_ProfileLevel
     *      kVTProfileLevel_H264_Baseline_AutoLevel
     *  2、GOP(关键帧间隔):
     *      kVTCompressionPropertyKey_MaxKeyFrameInterval
     *  3、编码后的帧率:
     *      kVTCompressionPropertyKey_ExpectedFrameRate；
     *      改变该值可以加快视频速度或者减慢视频速度
     *  4、编码后的平均码率：
     *      kVTCompressionPropertyKey_AverageBitRate
     *      平均码率决定了压缩的程度
     *  5、编码后的码率上限：
     *      kVTCompressionPropertyKey_DataRateLimits
     */
    // 设置实时编码输出（避免延迟）
    VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    /** 设置H264编码的压缩级别
     *  BP(Baseline Profile)：基本画质。支持I/P 帧，只支持无交错（Progressive）和CAVLC；主要应用：可视电话，会议
     *  电视，和无线通讯等实时视频通讯领域
     *  EP(Extended profile)：进阶画质。支持I/P/B/SP/SI 帧，只支持无交错（Progressive）和CAVLC；
     *  MP(Main profile)：主流画质。提供I/P/B 帧，支持无交错（Progressive）和交错（Interlaced），也支持CAVLC 和CABAC 的支持；主要应用：数字广播电视和数字视频存储
     *  HP(High profile)：高级画质。在main Profile 的基础上增加了8×8内部预测、自定义量化、 无损视频编码和更多的YUV 格式；
     *  应用于广电和存储领域
     *  iPhone上方案如下：
     *  实时直播：
     *      低清Baseline Level 1.3
     *      标清Baseline Level 3
     *      半高清Baseline Level 3.1
     *      全高清Baseline Level 4.1
     *  存储媒体：
     *  低清 Main Level 1.3
     *  标清 Main Level 3
     *  半高清 Main Level 3.1
     *  全高清 Main Level 4.1
     *  高清存储：
     *  半高清 High Level 3.1
     *  全高清 High Level 4.1
     *
     *  参考文章：https://blog.csdn.net/sphone89/article/details/17492433
     */
    VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_AutoLevel);
    // 设置是否开启B帧编码;默认开启，注意只有EP，MP，HP级别才支持B帧，如果是BP级别，该设置无效。
    VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanTrue);
    /** 设置关键帧GOP间隔
     *  1、码率不变的前提下，GOP值越大P、B帧的数量会越多，平均每个I、P、B帧所占用的字节数就越多，也就更容易获取较好的图像质量；B帧的数量越多，同
     *  理也更容易获得较好的图像质量;
     *  2、需要说明的是，通过提高GOP值来提高图像质量是有限度的，在遇到场景切换的情况时，H.264编码器会自动强制插入一个I帧，此时实际的GOP值被缩短了。
     *  另一方面，在一个GOP中，P、B帧是由I帧预测得到的，当I帧的图像质量比较差时，会影响到一个GOP中后续P、B帧的图像质量，直到下一个GOP开始才有
     *  可能得以恢复，所以GOP值也不宜设置过大。
     *  3、同时，由于P、B帧的复杂度大于I帧，所以过多的P、B帧会影响编码效率，使编码效率降低。另外，过长的GOP还会影响Seek操作的响应速度，由于P、B帧
     *  是由前面的I或P帧预测得到的，所以Seek操作需要直接定位，解码某一个P或B帧时，需要先解码得到本GOP内的I帧及之前的N个预测帧才可以，GOP值越长
     *  需要解码的预测帧就越多，seek响应的时间也越长。
     */
    int iFrameInternal = 10;
    CFNumberRef iFrameRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &iFrameInternal);
    VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, iFrameRef);
    // 设置期望帧率
    int fps = 25;
    CFNumberRef fpsRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &fps);
    VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_ExpectedFrameRate, fpsRef);
    
    /** 设置均值码率，单位是bps，它不是一个硬性指标，实际的码率可能会上下浮动;VideoToolBox框架只支持ABR模式，而对于H264来说，它有四种
     *  码率控制模式，如下：
     *  CBR:恒定比特率方式进行编码，Motion发生时，由于码率恒定，只能通过增大QP来减少码字大小，图像质量变差，当场景静止时，图像质量又变好
     *      因此图像质量不稳定。这种算法优先考虑码率(带宽)。
     *  VBR:动态比特率，其码率可以随着图像的复杂程度的不同而变化，因此其编码效率比较高，Motion发生时，马赛克很少。码率控制算法根据图像
     *      内容确定使用的比特率，图像内容比较简单则分配较少的码率(似乎码字更合适)，图像内容复杂则分配较多的码字，这样既保证了质量，又
     *      兼顾带宽限制。这种算法优先考虑图像质量。
     * CVBR:它是VBR的一种改进方法这种算法对应的Maximum bitRate恒定或者Average BitRate恒定。这种方法的兼顾了以上两种方法的优点,
     *      在图像内容静止时，节省带宽，有Motion发生时，利用前期节省的带宽来尽可能的提高图像质量，达到同时兼顾带宽和图像质量的目的
     *  ABR:在一定的时间范围内达到设定的码率，但是局部码率峰值可以超过设定的码率，平均码率恒定。可以作为VBR和CBR的一种折中选择。
     *
     *  H264各个分辨率推荐的码率表:http://www.lighterra.com/papers/videoencodingh264/
     */
    SInt32 avgbitRate = 0.96*1000000;   // 注意单位是bit/s 这里是640x480的 为0.96Mbps
    CFNumberRef avgRateLimitRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &avgbitRate);
    VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_AverageBitRate, avgRateLimitRef);
    /** 遇到问题：编码的视频马赛克严重
     *  原因分析：没有正确的设置码率上限值
     *  解决思路：正确设置码率上限
     *
     *  备注：码率上限一个数组，按照@[比特数,时长.....]方式传值排列，至少一对 比特数,时长；如果有多个，这些值必须平滑，内部会有一个算法算出最终值
     *  均值码率过低，也会造成马赛克
     */
    // 设置码率上限
    int bitRateLimits = avgbitRate; // 一秒钟的最大码率
    NSArray *limit = @[@(bitRateLimits * 1.5), @(1)];
    VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFArrayRef)limit);
    // 初始化编码器，进行准备
    status = VTCompressionSessionPrepareToEncodeFrames(_encodeSession);
    if (status == noErr) {
        NSLog(@"CompressionSession 初始化成功 可以开始解码了");
    }
}

- (BOOL)encodeWithSampleRef:(CVImageBufferRef)imageref
{
    
    // 关于CVImageBufferRef操作相关函数 在头文件<CoreVideo/CVPixelBuffer.h>中
    /** 执行编码
     *  参数1：已经创建并且准备好的VTCompressionSessionRef对象
     *  参数2：具体的视频原始数据;CVImageBufferRef类型
     *  参数3：视频数据开始编码的时间;CMTime类型，一般是CMTimeMake(帧序号, 压缩单位(比如1000));
     *  参数4：该帧视频的时长，一般不需要计算(因为没法算)，传kCMTimeInvalid即可
     *  参数5：要编码的视频相关属性；CFDictionaryRef类型
     *  参数6：传递给编码输出回调的参数;void* 类型
     *  参数7：编码结果标记；通过回调函数获取
     */
    // 帧序号时间，用于表示帧开始编码的时间(备注：这个时间是相对时间，并不是真正时间)
    CMTime presentationTime = CMTimeMake(_frameId++, 1000);
    VTEncodeInfoFlags encodeflags;
    OSStatus status = VTCompressionSessionEncodeFrame(_encodeSession, imageref, presentationTime, kCMTimeInvalid, NULL, NULL, &encodeflags);
    if (status != noErr) {
        NSLog(@"VTCompressionSessionEncodeFrame fail %d",status);
        
        // 释放资源
        VTCompressionSessionInvalidate(_encodeSession);
        CFRelease(_encodeSession);
        _encodeSession = NULL;
    }
    
    return YES;
}

- (void)releaseCompression
{
    // 释放编码器资源
    VTCompressionSessionInvalidate(_encodeSession);
    CFRelease(_encodeSession);
    _encodeSession = NULL;
}

/** 编码完成回调
 *  参数1：由创建编码器的函数VTCompressionSessionCreate()指定
 *  参数2：由进行编码的函数VTCompressionSessionEncodeFrame()指定
 *  参数3：编码结果；noErr表示正确
 *  参数4：VTEncodeInfoFlags；由VTCompressionSessionEncodeFrame()指定
 *  参数5：编码后的视频数据结构体，包含了编码后的参数以及具体的编码数据
 *
 *  备注：CMSampleBufferRef中可能包含多个NALU视频数据
 */
void didCompressH264(void *outputCallbackRefCon, void *sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sampleBuffer)
{
    NSLog(@"didCompressH264 called with status %d infoFlags %d", (int)status, (int)infoFlags);
    if (status != noErr) {
        NSLog(@"compress fail %d",status);
        return;
    }
    
    // 返回该sampleBuffer是否可以进行操作了
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        NSLog(@"CMSampleBufferDataIsReady is not ready");
        return;
    }
    
    ADVTEncoder *mySelf = (__bridge ADVTEncoder*)outputCallbackRefCon;
    // CMSampleBufferGetSampleAttachmentsArray获取视频帧的描述信息，比如是否关键帧等等;kCMSampleAttachmentKey_NotSync标记是否关键帧
    BOOL keyframe = CFDictionaryContainsKey(CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES), 0), kCMSampleAttachmentKey_NotSync);
    if (keyframe) {
        /** CMFormatDescriptionRef中包含了PPS/SPS/SEI，宽高、颜色空间、编码格式等描述信息的结构体，它等同于
         *  CMVideoFormatDescriptionRef
         *  SPS在索引0处；PPS在索引1处
         */
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        size_t SPSSize, SPSCount;
        const uint8_t *sps;
        OSStatus retStatus = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sps, &SPSSize, &SPSCount, 0);
        if (retStatus == noErr) {
            size_t PPSSize, PPSCount;
            const uint8_t *pps;
            retStatus = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pps, &PPSSize, &PPSCount, 0);
            if (retStatus == noErr) {
                NSData *spsData = [NSData dataWithBytes:sps length:SPSSize];
                NSData *ppsData = [NSData dataWithBytes:pps length:PPSSize];
                
                // 保存sps和pps
                [mySelf saveSPS:spsData pps:ppsData];
            }
        }
    }
    
    // CMBlockBufferRef表示一个内存块,用来存放编码后的音频/视频数据
    CMBlockBufferRef dataBlockRef = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t lenght,totalLenght;
    char *dataptr;
    // 获取指向内存块数据的指针
    OSStatus status1 = CMBlockBufferGetDataPointer(dataBlockRef, 0, &lenght, &totalLenght, &dataptr);
    if (status1 == noErr) {
        size_t bufferOffset = 0;
        static const int AACStartCodeLenght = 4;
        /** 一次编码可能会包含多个nalu
         *  所以要循环获取所有的nalu数据，并解析出来
         *  每个NALU的格式为
         *  四字节(NALU总长度)+视频数据(NALU总长度-4)
         *  和正规的h264的nalu封装格式0001开头的有点不一样
         */
        while (bufferOffset < totalLenght - AACStartCodeLenght) {
            uint32_t naluUnitLenght = 0;
            // 读取该NALU的数据总长度，该NALU就是一帧完整的编码的视频
            memcpy(&naluUnitLenght, dataptr+bufferOffset, AACStartCodeLenght);
            
            // 返回的nalu数据前四个字节不是0001的startcode，而是大端模式的帧长度length
            // 从大端转系统端(必须，否则会造成长度错误问题)
            naluUnitLenght = CFSwapInt32BigToHost(naluUnitLenght);
            // 将真正的编码后的视频帧提取出来
            NSData *data = [[NSData alloc] initWithBytes:(dataptr + bufferOffset + AACStartCodeLenght) length:naluUnitLenght];
            
            // 然后添加0001开头码组成正规的h264封装格式
            [mySelf saveEncodedData:data isKeyFrame:keyframe];
            
            // 循环读取
            bufferOffset += AACStartCodeLenght + naluUnitLenght;
        }
    }
}

- (void)saveSPS:(NSData*)sps pps:(NSData*)pps
{
//    NSLog(@"gotSpsPps %d %d", (int)[sps length], (int)[pps length]);
//    const char bytes[] = "\x00\x00\x00\x01";
//    size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
//    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
//    [self.mDataWriter writeData:ByteHeader];
//    [self.mDataWriter writeData:sps];
//    [self.mDataWriter writeData:ByteHeader];
//    [self.mDataWriter writeData:pps];
}

- (void)saveEncodedData:(NSData*)data isKeyFrame:(BOOL)isKeyFrame
{
//    NSLog(@"gotEncodedData %d", (int)[data length]);
//    const char bytes[] = "\x00\x00\x00\x01";
//    size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
//    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
//    [self.mDataWriter writeData:ByteHeader];
//    [self.mDataWriter writeData:data];
}
@end
