//
//  CodecBase.cpp
//  media
//
//  Created by 飞拍科技 on 2019/8/9.
//  Copyright © 2019 飞拍科技. All rights reserved.
//

#include "CodecBase.hpp"
CodecBase::CodecBase(CodecType type,CodecIDType encodeId)
:fCodecType(type),fCodeIdType(encodeId),pCodecCtx(NULL),pCodec(NULL),pFrame(NULL)
{
    LOGD("CodecBase");
    if (fCodecType == CodecTypeEncoder) {
        initEnCodecContext(encodeId);
    } else if (fCodecType == CodecTypeDecoder){
        initDeCodecContext(encodeId);
    } else {
        assert("不支持的类型呢");
    }
}

CodecBase::~CodecBase()
{
    LOGD("~CodecBase");
}
enum AVCodecID CodecBase::getCodecIdWithId(CodecIDType encodeId)
{
    enum AVCodecID cId = AV_CODEC_ID_H264;
    if (encodeId == CodecIDTypeH264) {
        cId = AV_CODEC_ID_H264;
    } else if (encodeId == CodecIDTypeAAC) {
        cId = AV_CODEC_ID_AAC;
    } else if (encodeId == CodecIDTypeMP3) {
        cId = AV_CODEC_ID_MP3;
    }
    
    return cId;
}
void CodecBase::initEnCodecContext(CodecIDType encodeId)
{
    LOGD("initEnCodecContext");
    enum AVCodecID cId = getCodecIdWithId(encodeId);
    pCodec = avcodec_find_encoder(cId);
    if (pCodec == nullptr) {
        LOGD("avcodec_find_encoder fail,encodeId %d 不存在",encodeId);
        return;
    }
    
    pCodecCtx = avcodec_alloc_context3(pCodec);
    if (pCodecCtx == nullptr) {
        LOGD("avcodec_alloc_context3 fail");
        return;
    }
}

/** -std=c++11，支持C++11标准；-std=gnu++11，支持C++11标准和GNU扩展特性；
 *  c++中NULL、0、nullptr区别：
 *  1、nullptr c++11以后版本才有的特性。
 *  2、C++中NULL和0是等同的，对于重载函数，比如对于两个重载的函数void func（int);void func（char*);如果
 *  调用func(NULL)是最终将调用void func（int)函数，从而导致错误(C语言中没有函数重载，所以没有这样问题)
 *  nullptr则是用于区分NULL和0的，func(nullptr)则肯定会调用void func（char*);
 *  所以，除了作为函数参数传空指针建议使用nullptr外，其它情况可以都使用NULL和nullptr
 */
void CodecBase::initDeCodecContext(CodecIDType encodeId)
{
    LOGD("initDeCodecContext");
    enum AVCodecID cId = getCodecIdWithId(encodeId);
    pCodec = avcodec_find_decoder(cId);
    if (pCodec == nullptr) {
        LOGD("avcodec_find_decoder fail,encodeId %d 不存在",encodeId);
        return;
    }
    
    pCodecCtx = avcodec_alloc_context3(pCodec);
    if (pCodecCtx == nullptr) {
        LOGD("avcodec_alloc_context3 fail");
        return;
    }
}
