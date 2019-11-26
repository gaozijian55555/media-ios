//
//  SFVideoEncoder.h
//  media
//
//  Created by 飞拍科技 on 2019/7/22.
//  Copyright © 2019 飞拍科技. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XRZCommonDefine.h"
#import "VideoParameters.h"

@protocol VideoEncodeProtocal <NSObject>

- (void)didEncodeSucess:(VideoPacket*)packet;
- (void)didEncodeFail:(NSError*)error;

@end
@interface SFVideoEncoder : NSObject

@property(nonatomic,weak)id<VideoEncodeProtocal>delegate;

// ========= 保存h264码流 ========= //
@property(nonatomic,assign)BOOL enableWriteToh264;
@property(nonatomic,copy)NSString   *h264FilePath;  // h264保存地址
// ========= 保存h264码流 ========= //

- (void)test;

- (void)setParameters:(VideoParameters*)param;

/** 将未压缩数据送入编码器缓冲区开始编码，编码器会先缓冲数帧然后开始编码，缓冲数目与GOP大小有关
 *  1、编码回调协议中的方法didEncodeSucess:、VideoEncodeProtocal与此方法在同一线程
 *  2、该方法非线程安全的，如果在不同线程中调用此方法会造成不可预知问题
 */
- (void)encodeRawVideo:(VideoFrame*)yuvframe;

/** 将编码器缓冲区中还有未编码的数据，全部编码完成，然后释放编码器相关资源
 *  1、编码回调协议中的方法didEncodeSucess:、VideoEncodeProtocal与此方法在同一线程
 *  2、调用此方法后就不能再调用encodeRawVideo方法了
 *  3、非线程安全的，此方法要和encodeRawVideo在同一线程调用，否则会造成无法预知问题
 */
- (void)flushEncode;

/** 关闭编码器；
 *  1、如果编码器缓冲区中含有未编码完的数据，该方法调用后将清除这部分数据，然后立即停止编码工作和释放编码器相关工作
 *  2、如果此方法要和encodeRawVideo方法再不同一线程中调用，这样才会立即停止编码工作，否则会等待剩余编码工作全部结束才返回
 */
- (void)closeEncoder;
@end
