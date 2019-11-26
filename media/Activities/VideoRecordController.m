//
//  VideoRecordController.m
//  media
//
//  Created by 飞拍科技 on 2019/7/22.
//  Copyright © 2019 飞拍科技. All rights reserved.
//

#import "VideoRecordController.h"
#import <VideoToolbox/VideoToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "DataWriter.h"
#import "XRZCommonDefine.h"
#import "SFVideoEncoder.h"
#import "ADVTEncoder.h"
#import "FileMuxer.h"

/** 使用相机必须在info.plist中申请NSCameraUsageDescription权限
 */
@interface VideoRecordController ()<AVCaptureVideoDataOutputSampleBufferDelegate,VideoEncodeProtocal>
{
    dispatch_queue_t captureQueue;  // 采集数据的线程
    dispatch_queue_t encodeQueue;  // 编码数据的线程
    
    uint8_t *bufForU,*bufForV;
    BOOL    isEncoding;
    int     _width,_height; // 录制视频的宽和高
    
    SFVideoEncoder  *_sfVideoEncoder;
    FileMuxer       *_fileMuxer;
    
    dispatch_source_t _timer;
}
@property (strong, nonatomic) UIButton *beginButton;
@property (strong, nonatomic) UIButton *hardEncodeButton;
@property (strong, nonatomic) UIButton *softEncodeButton;
@property (strong, nonatomic) UILabel  *infoLabel;

// 管理视频输入输出的会话(输入：摄像头；输出：输送数据给app端)
@property (strong, nonatomic) AVCaptureSession          *mCaptureSession;
// 代表具体的视频输入设备
@property (strong, nonatomic) AVCaptureDeviceInput      *mCaptureInput;
// 代表具体输出视频给app端
@property (strong, nonatomic) AVCaptureVideoDataOutput  *mVideoDataOutput;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer*mVideoPreviewLayer;

@property (strong, nonatomic) DataWriter           *mDataWriter;
@property (strong, nonatomic) NSString             *mSavePath;
// 开始时间
@property (assign, nonatomic) NSInteger            mTimerCount;

@end

@implementation VideoRecordController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    captureQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    self.beginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.beginButton.frame = CGRectMake(60, 50, 100, 50);
    [self.beginButton setTitle:@"开启摄像头" forState:UIControlStateNormal];
    [self.view addSubview:self.beginButton];
    [self.beginButton addTarget:self action:@selector(onTapBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *hardEncode = [UIButton buttonWithType:UIButtonTypeSystem];
    hardEncode.frame = CGRectMake(170, 50, 60, 50);
    [hardEncode setTitle:@"硬编码" forState:UIControlStateNormal];
    [self.view addSubview:hardEncode];
    [hardEncode addTarget:self action:@selector(onTapHardEncodeBtn:) forControlEvents:UIControlEventTouchUpInside];
    self.hardEncodeButton = hardEncode;
    
    UIButton *softEncode = [UIButton buttonWithType:UIButtonTypeSystem];
    softEncode.frame = CGRectMake(240, 50, 60, 50);
    [softEncode setTitle:@"软编码" forState:UIControlStateNormal];
    [self.view addSubview:softEncode];
    [softEncode addTarget:self action:@selector(onTapSoftEncodeBtn:) forControlEvents:UIControlEventTouchUpInside];
    self.softEncodeButton=softEncode;
    
    self.infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 100, 350, 60)];
    self.infoLabel.backgroundColor = [UIColor blackColor];
    self.infoLabel.textColor = [UIColor whiteColor];
    self.infoLabel.font = [UIFont systemFontOfSize:8];
    [self.view addSubview:self.infoLabel];
    
    // 初始化原始视频文件
    self.mSavePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"abc.yuv"];
    self.mDataWriter = [[DataWriter alloc] initWithPath:self.mSavePath];
    _width = 480;
    _height = 640;
    
    bufForU = NULL;
    bufForV = NULL;
    
    // 初始化编码器
    _sfVideoEncoder = [[SFVideoEncoder alloc] init];
    _sfVideoEncoder.enableWriteToh264 = YES;
    _sfVideoEncoder.h264FilePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"abc-test.h264"];
    _sfVideoEncoder.delegate = self;
    // H264各个分辨率推荐的码率表:http://www.lighterra.com/papers/videoencodingh264/
    int avgbitRate = 2.56*1000000;
    /** 遇到问题：编码器缓冲的视频帧数量过大导致内存暴涨
     *  解决方案：经过调试，发现编码器缓存的视频数目=gopsize+b帧数目+4；通过控制gopsize和b帧数目来控制缓存的视频数目大小
     */
    [_sfVideoEncoder setParameters:[[VideoParameters alloc] initWithWidth:_width height:_height pixelformat:MZPixelFormatYUV420P fps:30 gop:10 bframes:3 bitrate:avgbitRate]];
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_sfVideoEncoder setParameters:NULL];
}

- (void)onTapBtn:(UIButton*)btn
{
    if (self.mCaptureSession.isRunning) {
        [self.mCaptureSession stopRunning];
        self.mCaptureSession = nil;
        
        [self.beginButton setTitle:@"开启摄像头" forState:UIControlStateNormal];
        self.hardEncodeButton.enabled = YES;
        self.softEncodeButton.enabled = YES;
        if (_timer) {
            dispatch_cancel(_timer);
            _timer = nil;
        }
        _mTimerCount = 0;
        return;
    }
    [self.beginButton setTitle:@"停止" forState:UIControlStateNormal];
    if (!_timer) {
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(_timer, ^{
            _mTimerCount++;
            self.infoLabel.text = [NSString stringWithFormat:@"录制时间 %d 秒",_mTimerCount];
        });
        dispatch_resume(_timer);
    }
    
    self.hardEncodeButton.enabled = NO;
    self.softEncodeButton.enabled = NO;
    [self initVideoCaptureSession];
    [self startRunCapSession];
}

- (void)onTapHardEncodeBtn:(UIButton*)btn
{
    if (isEncoding) {
        isEncoding = NO;
        self.softEncodeButton.enabled = YES;
        self.beginButton.enabled = YES;
    } else {
        self.softEncodeButton.enabled = NO;
        self.beginButton.enabled = NO;
        isEncoding = YES;
    }
}

- (void)onTapSoftEncodeBtn:(UIButton*)btn
{
    if (isEncoding) {
        isEncoding = NO;
        [self endSoftEncode];
        NSLog(@"endSoft %d",isEncoding);
    } else {
        if ([self.mDataWriter fileIsExsits]) {
            self.hardEncodeButton.enabled = NO;
            self.beginButton.enabled = NO;
            isEncoding = YES;
            [self performSelectorInBackground:@selector(beginSoftEncode) withObject:nil];
        } else {
            self.infoLabel.text = @"文件不存在!";
        }
    }
}

- (void)initVideoCaptureSession
{
    // 初始化AVCaptureSession
    self.mCaptureSession = [[AVCaptureSession alloc] init];
    // 配置输出图像的分辨率;注意实际录制出来的宽和高是反的
    self.mCaptureSession.sessionPreset = AVCaptureSessionPreset640x480;
    
    /** AVCaptureDevice
     *  代表了一个具体的物理设备，比如摄像头(前置/后置)，扬声器等等
     *  备注：模拟器无法运行摄像头相关代码
     */
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
    
    // 根据物理设备创建输入对象
    self.mCaptureInput = [[AVCaptureDeviceInput alloc] initWithDevice:videoDevice error:nil];
    
    // 将AVCaptureDeviceInput对象添加到AVcaptureSession中进行管理；添加之前检查一下是否支持该设备类型
    // AVCaptureDeviceInput是AVCaptureInput(它是一个抽象类)的子类
    if ([self.mCaptureSession canAddInput:self.mCaptureInput]) {
        [self.mCaptureSession addInput:self.mCaptureInput];
    }
    
    // 创建视频输出对象AVCaptureVideoDataOutput对象；AVCaptureVideoDataOutput是
    // AVCaptureOutput(它是一个抽象类)的子类
    self.mVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    // 当回调因为耗时操作还在进行时，系统对新的一帧图像的处理方式，如果设置为YES，则立马丢弃该帧。
    // NO，则缓存起来(如果累积的帧过多，缓存的内存将持续增长)；该值默认为YES
    self.mVideoDataOutput.alwaysDiscardsLateVideoFrames = NO;
    /** 设置采集的视频数据帧的格式。这里代表生成的图像数据为YUV数据，颜色范围是full-range的
     *  并且是bi-planner存储方式(也就是Y数据占用一个内存块;UV数据占用另外一个内存块)
     *  对于相机，只支持420v(ios5 前使用)，420f(颜色范围更广，一般用这个)，BGRA三种格式
     */
//    NSArray *avails = [self.mVideoDataOutput availableVideoCVPixelFormatTypes];
//    for (NSNumber *cur in avails) {
//        NSInteger n = cur.integerValue;
//        NSLog(@"log %c%c%c%c",(n>>24)&0xFF,(n>>16)&0xFF,(n>>8)&0xFF,n&0xFF);
//    }
    [self.mVideoDataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    // 设置视频输出的回调代理
    [self.mVideoDataOutput setSampleBufferDelegate:self queue:captureQueue];
    if ([self.mCaptureSession canAddOutput:self.mVideoDataOutput]) {
        [self.mCaptureSession addOutput:self.mVideoDataOutput];
    }
    
    /** AVCaptureConnection代表了AVCaptureInputPort和AVCaptureOutput、
     *  AVCaptureVideoPreviewLayer之间的连接通道，通过它可以将视频数据输送给
     *  AVCaptureVideoPreviewLayer进行显示
     *  设置输出视频的输出视频的方向，镜像等等。
     */
    AVCaptureConnection *connection = [self.mVideoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    
    /** AVCaptureVideoPreviewLayer是一个可以显示摄像头内容的CAlayer的子类
     *  以下代码直接将摄像头的内容渲染到AVCaptureVideoPreviewLayer上面
     */
    self.mVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.mCaptureSession];
    [self.mVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    [self.mVideoPreviewLayer setFrame:CGRectMake(0, 150, self.view.frame.size.width, self.view.frame.size.height - 250)];
    [self.view.layer addSublayer:self.mVideoPreviewLayer];
}

- (void)startRunCapSession
{
    if (!self.mCaptureSession.isRunning) {
        // 删除目录重新录制
        [self.mDataWriter deletePath];
        
        [self.mCaptureSession startRunning];
    }
}
- (void)stopRunCapSession
{
    if (self.mCaptureSession.isRunning) {
        [self.mCaptureSession stopRunning];
    }
    
    [_mVideoPreviewLayer removeFromSuperlayer];
    
}

/** CMSampleBufferRef 功能如下：
 *  1、包含音视频描述信息，比如包含音频的格式描述 AudioStreamBasicStreamDescription、包含视频的格式描述 CMVideoFormatDescriptionRef
 *  2、包含音视频数据，可以是原始数据也可以是压缩数据;通过CMSampleBufferGetxxx()系列函数提取
 */
- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    NSLog(@"被丢弃了的数据 ==>%@",[NSThread currentThread]);
}

/** 回调函数的线程不固定
 */
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    NSLog(@"采集到的数据 ==>%@",[NSThread currentThread]);
    /** CVImageBufferRef 表示原始视频数据的对象；
     *  包含未压缩的像素数据，包括图像宽度、高度等；
     *  等同于CVPixelBufferRef
     */
    // 获取CMSampleBufferRef中具体的视频数据
    CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // 锁住 内存块；根据官网文档的注释，不锁住可能会造成内存泄漏
    CVReturn result = CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    if (result != kCVReturnSuccess) {
        return;
    }
    
    // 获取数据的类型;必须是CVPixelBufferGetTypeID()返回的类型
    CFTypeID imageType = CFGetTypeID(imageBuffer);
    // 由于相机录制生成的视频只支持420v，420f，BGRA三种格式，前面两种对应于ffmpeg的AV_PIX_FMT_NV12
    OSType pixelFormatType = CVPixelBufferGetPixelFormatType(imageBuffer);
    
    if (imageType == CVPixelBufferGetTypeID() && (pixelFormatType == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange || pixelFormatType == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)) {
        size_t count = CVPixelBufferGetPlaneCount(imageBuffer);
        UInt8 *yBytes = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
        UInt8 *uvBytes = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1);
        // 代表了内存的组织方式，与CVPixelBufferGetWidthOfPlane()值不一定相等，两者没有任何联系
        size_t yBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
        size_t uvBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 1);
        size_t w1 = CVPixelBufferGetWidthOfPlane(imageBuffer, 0);
        size_t w2 = CVPixelBufferGetWidthOfPlane(imageBuffer, 1);
        size_t h1 = CVPixelBufferGetHeightOfPlane(imageBuffer, 0);
        size_t h2 = CVPixelBufferGetHeightOfPlane(imageBuffer, 1);
        NSLog(@"count %ld yr %ld,uvr %ld w1 %ld, %ld,%ld,%ld",count,yBytesPerRow,uvBytesPerRow,w1,w2,h1,h2);
        
        // 将yuv数据按照I420P的方式存入文件(YYYYYY....U......V......)
        // 先写入 Y的数据
        [self.mDataWriter writeDataBytes:yBytes len:w1*h1];
        // 再写入 UV的数据
        size_t uvlen = w1*h1/4;
        if (bufForU == NULL) {
            bufForU = malloc(uvlen);
            bufForV = malloc(uvlen);
        }
        // 每次重置数据
        memset(bufForU, 0, uvlen);
        
        // 将UV分离出来并保存到指定的文件中，之后可以直接用ffplay命令播放yuv文件了；UV占的字节数为Y的一半，切按照uv的顺序交叉存储
        /** 遇到问题，ffplay播放时视频不对。
         *  解决方案：手机分辨率是垂直的，录制视频的宽和高与前面设置视频分辨率刚好是相反的，举例，比如前面设置的为640x480，实际输出画面的宽高
         *  为480x640
         */
        for (int i=0,j=0; j<w1*h1/2; j+=2,i++) {
            bufForU[i]=uvBytes[j];
            bufForV[i]=uvBytes[j+1];
        }
        [self.mDataWriter writeDataBytes:bufForU len:uvlen];
        [self.mDataWriter writeDataBytes:bufForV len:uvlen];
    }
    
    // 解锁内存块
    CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
}


- (void)beginSoftEncode
{
    // 以二进制方式读取文件
    FILE *yuvFile = fopen([self.mSavePath UTF8String], "rb");
    if (yuvFile == NULL) {
        NSLog(@"打开YUV 文件失败");
        return;
    }
    if (_width <= 0 || _height <= 0) {
        NSLog(@"宽度和高度不能为 0");
        return;
    }
    
    NSLog(@"开始 拉取视频 ==>%@",[NSThread currentThread]);
    NSDate *begindate = [NSDate date];
    NSInteger count = 0;
    // 读取YUV420 planner格式的视频数据，其一帧视频数据的大小为 宽*高*3/2;
    VideoFrame *frame = (VideoFrame*)malloc(sizeof(VideoFrame));
    frame->luma = (uint8_t*)malloc(_width * _height);
    frame->chromaB = (uint8_t*)malloc(_width * _height/4);
    frame->chromaR = (uint8_t*)malloc(_width * _height/4);
    frame->width = _width;
    frame->height = _height;
    frame->cv_pixelbuffer = NULL;
    frame->full_range = 0;
    
    while (isEncoding) {
        memset(frame->luma, 0, _width * _height);
        memset(frame->chromaB, 0, _width * _height/4);
        memset(frame->chromaR, 0, _width * _height/4);
        
        size_t size = fread(frame->luma, 1, _width * _height, yuvFile);
        size = fread(frame->chromaB, 1, _width * _height/4, yuvFile);
        size = fread(frame->chromaR, 1, _width * _height/4, yuvFile);
        
        if (size == 0) {
            NSLog(@"读取的数据字节为0");
            break;
        }
        
        // 开始编码
//        NSLog(@"开始编码 ==>%ld",size);
        count++;
        [_sfVideoEncoder encodeRawVideo:frame];
//
//        //xrz:todo 模拟停止编码动作
//        static NSInteger val=0;
//        if (val >= 50) {
//            dispatch_sync(dispatch_get_main_queue(), ^{
//                [_sfVideoEncoder closeEncoder];
//                [self endSoftEncode];
//            });
//            break;
//        }
//        val++;
        
        // 封装到MP4文件中
        if (_fileMuxer == nil) {
            // 初始化封装器
            NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"abc.h264"];;
            _fileMuxer = [[FileMuxer alloc] initWithPath:filePath];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [_fileMuxer openMuxer];
            });
        }
        
    }
    [_sfVideoEncoder flushEncode];
    
    NSTimeInterval intal = [[NSDate date] timeIntervalSinceReferenceDate] - [begindate timeIntervalSinceReferenceDate];
    NSLog(@"结束 拉取视频 编码耗时 %.2f 秒",intal);
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        self.infoLabel.text = [NSString stringWithFormat:@"编码总耗时 %.2f 秒;每帧平均耗时 %.2f 毫秒",intal,intal*1000/count];
        [self endSoftEncode];
    });
    
    // 释放资源
    fclose(yuvFile);
    if (frame->luma) {
        free(frame->luma);
        free(frame->chromaB);
        free(frame->chromaR);
    }
}
- (void)endSoftEncode
{
    isEncoding = NO;
    self.softEncodeButton.enabled = YES;
    self.hardEncodeButton.enabled = YES;
    self.beginButton.enabled = YES;
}

- (void)beginHardEncode
{
    
}


#pragma mark VideoEncodeProtocal
- (void)didEncodeSucess:(VideoPacket *)packet
{
    if (packet == NULL) {
        return;
    }
    
    if (_fileMuxer != NULL) {
        [_fileMuxer writeVideoPacket:packet];
    }
    
    
}

- (void)didEncodeFail:(NSError *)error
{
    NSLog(@"error %@",error);
}

/** 参考文章：
 *  1、http://www.enkichen.com/2017/11/26/image-h264-encode/
 *  2、http://www.enkichen.com/2018/03/24/videotoolbox/
 */
@end
