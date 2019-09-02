//
//  VideoCodecParameters.cpp
//  media
//
//  Created by apple on 2019/8/31.
//  Copyright © 2019 飞拍科技. All rights reserved.
//

#include "VideoCodecParameters.hpp"

// VideoCodecParameters ============ //
VideoCodecParameters::VideoCodecParameters()
{
    fCodecIdType = MZCodecIDTypeH264;
    LOGD("VideoCodecEncoderParameters()");
}

VideoCodecParameters::VideoCodecParameters(MZCodecIDType type,int width,int height,MZPixelFormat pixelformat,int fps,int brate,int gopsize,int bframes)
:fCodecIdType(type),fWidth(width),fHeight(height),fPixelFormat(pixelformat),fFps(fps),fBitrate(brate),fGOPSize(gopsize),fBFrameNum(bframes)
{
    LOGD("VideoCodecEncoderParameters(....)");
}

//VideoCodecParameters::VideoCodecParameters(VideoCodecParameters &par)
//{
//    LOGD("VideoCodecEncoderParameters(const VideoCodecParameters &par)");
//
//}

VideoCodecParameters::~VideoCodecParameters()
{
    LOGD("~VideoCodecEncoderParameters()");
}

bool VideoCodecParameters::operator!=(VideoCodecParameters paremeter)
{
    VideoCodecParameters par = paremeter;
    bool ok = true;
    if (par.fCodecIdType != fCodecIdType) {
        ok = false;
        LOGE("fCodecIdType not eqeal <=0");
    }
    
    if (par.getBitrate() != fBitrate) {
        ok = false;
        LOGE("fBitrate not eqeal <=0");
    }
    
    if (par.getWidth() != fWidth) {
        ok = false;
        LOGE("fBitrate not eqeal <=0");
    }
    
    if (par.getHeight() != fHeight) {
        ok = false;
        LOGE("fHeight not eqeal <=0");
    }
    if (par.getFps() != fFps) {
        ok = false;
        LOGE("fFps not eqeal");
    }
    if (par.getGOPSize() != fGOPSize) {
        ok = false;
        LOGE("fGOPSize not eqeal");
    }
    if (par.getBFrameNum() !=fBFrameNum) {
        ok = false;
        LOGE("fBFrameNum not eqeal");
    }
    if (par.getPixelFormat() !=fPixelFormat) {
        ok = false;
        LOGE("fPixelFormat not eqeal");
    }
    
    return true;
}
const int VideoCodecParameters::getWidth()
{
    return fWidth;
}
void VideoCodecParameters::setWidth(int width)
{
    fWidth = width;
}
const int VideoCodecParameters::getHeight()
{
    return fHeight;
}
void VideoCodecParameters::setHeight(int height)
{
    fHeight = height;
}
const int VideoCodecParameters::getFps()
{
    return fFps;
}
void VideoCodecParameters::setFPS(int fps)
{
    fFps = fps;
}
const int VideoCodecParameters::getBitrate()
{
    return fBitrate;
}
void VideoCodecParameters::setBitrate(int bRate)
{
    fBitrate = bRate;
}
void VideoCodecParameters::setGOPSize(int gopsize)
{
    fGOPSize = gopsize;
}
const int VideoCodecParameters::getGOPSize()
{
    return fGOPSize;
}
const int VideoCodecParameters::getBFrameNum()
{
    return fBFrameNum;
}
void VideoCodecParameters::setBFrameNum(int bframes)
{
    fBFrameNum = bframes;
}
void VideoCodecParameters::setPixelFormat(MZPixelFormat pixelformat)
{
    fPixelFormat = pixelformat;
}
const MZPixelFormat VideoCodecParameters::getPixelFormat()
{
    return fPixelFormat;
}

const AVPixelFormat VideoCodecParameters::avpixelformat()
{
    return AV_PIX_FMT_YUV420P;
}
