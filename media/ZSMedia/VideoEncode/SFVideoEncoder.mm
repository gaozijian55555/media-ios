//
//  SFVideoEncoder.m
//  media
//
//  Created by 飞拍科技 on 2019/7/22.
//  Copyright © 2019 飞拍科技. All rights reserved.
//

#import "SFVideoEncoder.h"
#include "VideoH264Encoder.hpp"

@implementation SFVideoEncoder
{
    VideoH264Encoder *_encoder;
    VideoCodecParameters _params;
}

- (id)init
{
    if (self = [super init]) {
        _encoder = new VideoH264Encoder();
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

- (BOOL)sendRawVideo:(VideoFrame*)yuvframe packet:(VideoPacket*)packet
{
    if (yuvframe == NULL || yuvframe->luma == NULL) {
        return NO;
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
    
    _encoder->sendRawVideoAndReceivePacketVideo(yuvframe, NULL);
    
    return YES;
}
- (BOOL)endEncode
{
    _encoder->flushAndReleaseEncoder();
    
    return true;
}
@end
