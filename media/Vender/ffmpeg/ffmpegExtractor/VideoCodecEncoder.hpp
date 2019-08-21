//
//  VideoCodecEncoder.hpp
//  media
//
//  Created by 飞拍科技 on 2019/8/12.
//  Copyright © 2019 飞拍科技. All rights reserved.
//

#ifndef VideoCodecEncoder_hpp
#define VideoCodecEncoder_hpp

#include "CodecBase.hpp"
#include "CommonDefine.h"
#include <stdio.h>

class VideoCodecEncoderParameters;
class VideoCodecEncoder:public CodecBase
{
public:
    VideoCodecEncoder();
    VideoCodecEncoder(const VideoCodecEncoderParameters& parameters);
    ~VideoCodecEncoder();
    
    // 设置编码相关参数
    void setParameters(const VideoCodecEncoderParameters& parameters);
    // 并开启编码器;true 成功开启，接下来可以调用编码相关函数;false 开启失败
    bool openEncoder();
    
    // 编码相关函数
    void sendEncode(VideoFrame *frame);
    
private:
    // 因为是类的前置声明，所以这里只能用指针类型
    VideoCodecEncoderParameters *fParameters;
    // 检验参数的合法性
    bool checkParametersValidate(const VideoCodecEncoderParameters& parameters);
    void resetFrame();
};

class VideoCodecEncoderParameters
{
public:
    VideoCodecEncoderParameters();
    VideoCodecEncoderParameters(CodecIDType type, int width,int height,AVPixelFormat pixelformat,int fps,int brate,int gopsize,int bframes);
    ~VideoCodecEncoderParameters();
    
    bool operator !=(const VideoCodecEncoderParameters& par);
    
    void setWidth(int width);
    const int getWidth();
    void setHeight(int height);
    const int getHeight();
    void setPixelFormat(AVPixelFormat pixelformat);
    const AVPixelFormat getPixelFormat();
    void setFPS(int fps);
    const int getFps();
    void setBitrate(int bRate);
    const int getBitrate();
    void setGOPSize(int gopsize);
    const int getGOPSize();
    void setBFrameNum(int bframes);
    const int getBFrameNum();
public:
    CodecIDType fCodecIdType;
    
private:
    
    int fWidth;
    int fHeight;
    AVPixelFormat fPixelFormat;
    int fFps;
    int fBitrate;
    int fGOPSize;
    int fBFrameNum;
};
#endif /* VideoEncoder_hpp */
