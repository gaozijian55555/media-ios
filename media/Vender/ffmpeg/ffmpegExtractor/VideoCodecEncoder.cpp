//
//  VideoCodecEncoder.cpp
//  media
//
//  Created by 飞拍科技 on 2019/8/12.
//  Copyright © 2019 飞拍科技. All rights reserved.
//

#include "VideoCodecEncoder.hpp"

VideoCodecEncoder::VideoCodecEncoder()
:CodecBase(CodecTypeEncoder,CodecIDTypeH264)
{
    
}

VideoCodecEncoder::VideoCodecEncoder(const VideoCodecEncoderParameters& par)
:CodecBase(CodecTypeEncoder,par.fCodecIdType)
{
    
}

VideoCodecEncoder::~VideoCodecEncoder()
{
    
}

void VideoCodecEncoder::setParameters(const VideoCodecEncoderParameters &parameters)
{
    if (pCodecCtx == nullptr) {
        LOGD("pCodecCtx is null");
        return;
    }
    
    if (!checkParametersValidate(parameters)) {
        LOGD("checkParametersValidate fail");
        return;
    }
    
    VideoCodecEncoderParameters pram = parameters;
    if (pram != *fParameters) {
        fCodeIdType = pram.fCodecIdType;
        fParameters = &pram;
    }
    
    /** 遇到问题：avcodec_open2()出错
     *  解决方案：在avcodec_open2()之前设置编码参数
     */
    AVCodecID codeid = getCodecIdWithId(fCodeIdType);
    // 编码方式Id 比如h264
    pCodecCtx->codec_id = codeid;
    // 类型，这里为视频
    pCodecCtx->codec_type = AVMEDIA_TYPE_VIDEO;
    // 原始视频的数据类型
    pCodecCtx->pix_fmt = pram.getPixelFormat();
    // 编码后的平均码率； 单位bit/s
    pCodecCtx->bit_rate = pram.getBitrate();
    // 视频编码用的时间基单位,通常值为{1,fps},此项设置必须有，用于决定编码后的帧率
    pCodecCtx->time_base = av_make_q(1, pram.getFps());
    // 视频宽，高
    pCodecCtx->width = pram.getWidth();
    pCodecCtx->height = pram.getHeight();
    // GOP size
    pCodecCtx->gop_size = pram.getGOPSize();
    // 一组 gop中b frame 的数目
    pCodecCtx->max_b_frames = pram.getBFrameNum();
    
    // x264编码特有的参数
    if (codeid == AV_CODEC_ID_H264) {
        av_opt_set(pCodecCtx->priv_data, "preset", "slow", 0);
        
        /** 遇到问题：将H264视频码流封装到MP4中后，无法播放；
         *  解决方案：加入如下代码
         *  Some formats want stream headers to be separate
         */
        pCodecCtx->flags |= AV_CODEC_FLAG2_LOCAL_HEADER;
    }
}

bool VideoCodecEncoder::openEncoder()
{
    if (pCodecCtx == nullptr) {
        LOGD("pCodecCtx is null");
        return false;
    }
    if (pCodec == NULL) {
        LOGD("pCodec is null");
        return false;
    }
    
    int ret = avcodec_open2(pCodecCtx, pCodec, NULL);
    if (ret < 0) {
        LOGD("avcodec_open2 fail %d",ret);
        return false;
    }
    
    return true;
}

void VideoCodecEncoder::sendEncode(VideoFrame *frame)
{
    if (frame == NULL) {
        LOGD("frame is null");
        return;
    }
    if (frame->chromaB == NULL) {
        LOGD("frame->chromaB is null");
        return;
    }
    
    if (pFrame == NULL) {
        pFrame = av_frame_alloc();

        pFrame->width = pCodecCtx->width;
        pFrame->height = pCodecCtx->height;
        pFrame->format = pCodecCtx->pix_fmt;
        // 为AVFrame分配存放视频数据的内存；av_frame_alloc()只是创建了不包含视频数据的内存
        av_frame_get_buffer(pFrame, 0);
        av_frame_make_writable(pFrame);
    }
}

void VideoCodecEncoder::resetFrame()
{
    if (pFrame) {
        
    }
}

bool VideoCodecEncoder::checkParametersValidate(const VideoCodecEncoderParameters &parameters)
{
    VideoCodecEncoderParameters par = parameters;
    bool ok = true;
    if (par.getBitrate() <= 0) {
        ok = false;
        LOGE("par.getBitrate() <=0");
    }
    
    if (par.getWidth() <= 0) {
        ok = false;
        LOGE("getWidth() <=0");
    }
    
    if (par.getHeight() <= 0) {
        ok = false;
        LOGE("getHeight() <=0");
    }
    
    if (par.getFps() <= 0) {
        ok = false;
        LOGE("getFps() <=0");
    }
    
    if (par.getGOPSize() <= 0) {
        ok = false;
        LOGE("getGOPSize() <=0");
    }
    
    return ok;
}

// VideoCodecEncoderParameters ============ //
VideoCodecEncoderParameters::VideoCodecEncoderParameters()
{
    fCodecIdType = CodecIDTypeH264;
    LOGD("VideoCodecEncoderParameters()");
}

VideoCodecEncoderParameters::VideoCodecEncoderParameters(CodecIDType type,int width,int height,AVPixelFormat pixelformat,int fps,int brate,int gopsize,int bframes)
:fCodecIdType(type),fWidth(width),fHeight(height),fPixelFormat(pixelformat),fFps(fps),fBitrate(brate),fGOPSize(gopsize),fBFrameNum(bframes)
{
    LOGD("VideoCodecEncoderParameters(....)");
}

VideoCodecEncoderParameters::~VideoCodecEncoderParameters()
{
    LOGD("~VideoCodecEncoderParameters()");
}

bool VideoCodecEncoderParameters::operator!=(const VideoCodecEncoderParameters &paremeter)
{
    VideoCodecEncoderParameters par = paremeter;
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
const int VideoCodecEncoderParameters::getWidth()
{
    return fWidth;
}
void VideoCodecEncoderParameters::setWidth(int width)
{
    fWidth = width;
}
const int VideoCodecEncoderParameters::getHeight()
{
    return fHeight;
}
void VideoCodecEncoderParameters::setHeight(int height)
{
    fHeight = height;
}
const int VideoCodecEncoderParameters::getFps()
{
    return fFps;
}
void VideoCodecEncoderParameters::setFPS(int fps)
{
    fFps = fps;
}
const int VideoCodecEncoderParameters::getBitrate()
{
    return fBitrate;
}
void VideoCodecEncoderParameters::setBitrate(int bRate)
{
    fBitrate = bRate;
}
void VideoCodecEncoderParameters::setGOPSize(int gopsize)
{
    fGOPSize = gopsize;
}
const int VideoCodecEncoderParameters::getGOPSize()
{
    return fGOPSize;
}
const int VideoCodecEncoderParameters::getBFrameNum()
{
    return fBFrameNum;
}
void VideoCodecEncoderParameters::setBFrameNum(int bframes)
{
    fBFrameNum = bframes;
}
void VideoCodecEncoderParameters::setPixelFormat(AVPixelFormat pixelformat)
{
    fPixelFormat = pixelformat;
}
const AVPixelFormat VideoCodecEncoderParameters::getPixelFormat()
{
    return fPixelFormat;
}
