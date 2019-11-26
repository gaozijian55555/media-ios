//
//  SFVideoEncoder.m
//  media
//
//  Created by 飞拍科技 on 2019/7/22.
//  Copyright © 2019 飞拍科技. All rights reserved.
//

#import "SFVideoEncoder.h"
#include "VideoH264Encoder.hpp"
#import "DataWriter.h"
extern "C"
{
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
}

void didCompressCallback(void*client,VideoPacket*pkt);

@implementation SFVideoEncoder
{
    VideoH264Encoder *_encoder;
    VideoCodecParameters _params;
    DataWriter  *_fileDataWriter;
}

- (id)init
{
    if (self = [super init]) {
        _encoder = new VideoH264Encoder();
        _encoder->setEncodeCallback((__bridge void*)self,didCompressCallback);
    }
    
    return self;
}

- (void)test
{
    _encoder = new VideoH264Encoder();
}

- (void)setParameters:(VideoParameters*)param
{
    if (param == nil) {
        return;
    }
    
    VideoCodecParameters par;
    par.setFPS(param.fps);
    par.setWidth(param.width);
    par.setHeight(param.height);
    par.setBitrate(param.bitRate);
    par.setGOPSize(param.GOP);
    par.setBFrameNum(param.maxBFrameNums);
    par.setPixelFormat(param.format);
    _params = par;
    
    _encoder->setParameters(par);
    _encoder->openEncoder();
}

- (void)setH264FilePath:(NSString *)h264FilePath
{
    if ([_h264FilePath isEqualToString:h264FilePath]) {
        return;
    }
    _h264FilePath = h264FilePath;
    _fileDataWriter = [[DataWriter alloc] initWithPath:h264FilePath];
    [_fileDataWriter deletePath];
}

- (void)encodeRawVideo:(VideoFrame*)yuvframe
{
    if (yuvframe == NULL || yuvframe->luma == NULL) {
        return;
    }
    if (!_encoder->canUseEncoder()) {
        _encoder->openEncoder();
    }
    
//    AVFrame *frame = av_frame_alloc();
//    frame->format = AV_PIX_FMT_YUV420P;
//    frame->width = yuvframe->width;
//    frame->height = yuvframe->height;
//    av_frame_get_buffer(frame, 0);
//    av_frame_make_writable(frame);
//    memcpy(frame->data[0], yuvframe->luma, yuvframe->width*yuvframe->height);
//    memcpy(frame->data[1], yuvframe->chromaB, yuvframe->width*yuvframe->height/4);
//    memcpy(frame->data[2], yuvframe->chromaR, yuvframe->width*yuvframe->height/4);
    
    _encoder->sendRawVideoAndReceivePacketVideo(yuvframe);
}

- (void)flushEncode
{
    NSLog(@"flushEncode");
    _encoder->flushEncoder();
    _encoder->closeEncoder();
}

- (void)closeEncoder
{
    NSLog(@"closeEncoder");
    _encoder->closeEncoder();
}

#pragma mark didCompressCallback
void didCompressCallback(void*client,VideoPacket*pkt)
{
    SFVideoEncoder *mySelf = (__bridge SFVideoEncoder*)client;
    if (mySelf.enableWriteToh264 && mySelf.h264FilePath) {
        [mySelf->_fileDataWriter writeDataBytes:pkt->data len:pkt->size];
    }
    if ([mySelf.delegate respondsToSelector:@selector(didEncodeSucess:)]) {
        [mySelf.delegate didEncodeSucess:pkt];
    }
}
@end
