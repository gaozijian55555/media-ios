//
//  Muxer.hpp
//  media
//
//  Created by apple on 2019/9/2.
//  Copyright © 2019 飞拍科技. All rights reserved.
//

#ifndef Muxer_hpp
#define Muxer_hpp
#include "CLog.h"

extern "C"
{
#include "libavutil/avutil.h"
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
}

#include <stdio.h>
#include <string>
using namespace std;

/** 用于写入到音视频数据的封装器
 */
class Muxer
{
public:
    Muxer(string filename);
    ~Muxer();
    
    typedef int ReadPacketFunc(void*clientData,uint8_t*buf,int buflen);
    
    // 设置读取音视/视频回调,要写入的音视频数据通过此回调函数传入AVFormatContext
    void setReadVideoPacketFunc(void* client,ReadPacketFunc *readfunction);
    void setReadAudioPacketFunc(void* client,ReadPacketFunc *readfunction);
    
    /** 开启和关闭封装流程。
     *  openMuxer();调用后，开启封装流程，内部会不停的驱动调用setReadVideoPacketFunc()和setReadAudioPacketFunc()设定的回调函数，通过此回调函数索要数据；
     *  外部不停的向此回调函数喂数据
     *  openMuxer();会阻塞当前线程
     *  closeMuxer();关闭封装流程；此函数和openMuxer()要在不同线程调用，否则closeMuxer()永远都不会调用
     */
    // 打开Muxer开始写入数据，
    bool openMuxer();
    // 关闭Muxer写入数据;调用此方法后，将保存所写入数据并生成文件
    void closeMuxer();
private:
    bool    mMuxerOpen;
    string  mFilename;
    int videoIndex_ou,audioIndex_ou;
    int videoIndex_in,audioIndex_in;
    
    ReadPacketFunc *pReadVideoFunc;
    void           *pVideoClient;
    ReadPacketFunc *pReadAudioFunc;
    void           *pAudioClient;
    
    // 用于写入数据的上下文
    AVFormatContext *pOFormatCtx;
    // 用于读取数据的上下文
    AVFormatContext *pIFormatCtx;
    // 用于对应于具体的音视频流
    AVStream        *pStream;
    
    // 根据文件名创建AVFormatContext;
    bool initMuxerformat(string filename);
    // 添加音/视频流AVStream
    bool addNewAVStream(AVFormatContext* informatCtx);

    // 通过码流信息推断输入格式
    AVFormatContext *iFormatFromBuffer(void* client,ReadPacketFunc bufFunc);
};
#endif /* Muxer_hpp */
