//
//  Muxer.cpp
//  media
//
//  Created by apple on 2019/9/2.
//  Copyright © 2019 飞拍科技. All rights reserved.
//

#include "Muxer.hpp"
#define Muxer_IO_buf_size (1024*1024*1)

Muxer::Muxer(string filename)
:pOFormatCtx(NULL),mMuxerOpen(false),mFilename(filename),pReadVideoFunc(NULL),pReadAudioFunc(NULL)
{
    LOGD("Muxer() %s",filename.c_str());
    if (filename.length() == 0) {
        LOGD("file name is null");
        return;
    }
    mFilename = filename;
    videoIndex_ou = -1;
    audioIndex_ou = -1;
    videoIndex_in = -1;
    audioIndex_in = -1;
}

Muxer::~Muxer()
{
    
}

bool Muxer::initMuxerformat(string filename)
{
    AVOutputFormat *oformat;
    
    int ret = 0;
    /** 1、创建用于往文件写入数据的AVFormatContext;
     *  将依次根据第二三四个参数推断出格式类型，然后创建 AVFormatContext，这里是根据文件名后缀推断
     *  会自动创建AVOutputFormat对象oformat，它代表了输出的数据格式等信息
     *  avformat_open_input()为创建从文件读取数据的AVFormatContext，会自动创建AVInputFormat对象iformat，它代表了读取到的数据的格式信息
     */
    ret = avformat_alloc_output_context2(&pOFormatCtx, NULL, NULL, filename.c_str());
    if (ret < 0) {
        LOGD("avformat_alloc_output_context2 fail %d",ret);
        return false;
    }
    oformat = pOFormatCtx->oformat;
    
    return true;
}

bool Muxer::addNewAVStream(AVFormatContext* informatCtx)
{
    bool success = false;
    
    for (int i=0; i<informatCtx->nb_streams; i++) {
        
        AVStream *instream = informatCtx->streams[i];
        // 添加视频流
        if (instream->codecpar->codec_type == AVMEDIA_TYPE_VIDEO && videoIndex_ou != -1) {
            /** 2、给AVFormatContext添加对应的输出流(音视频流)，并且为它们赋值正确的封装格式参数
             *  AVStream用于和具体的音/视频/字母等数据流关联;对于往文件写入数据，必须在avformat_write_header()函数前手动创建
             *  对于从文件中读取数据，在其它函数内部自动创建
             */
            /** 给写入数据的AVFormatContext输出流AVStream赋值音视频的格式参数，这样封装的时候文件头信息才会正确写入。赋值格式参数有两种方式
             *  方式一：从另一个AVFormatContext所对应的AVStream中拷贝，常用语没有经过编码的二次封装
             *  方式二：从AVCodecContext编解码器上下文中拷贝
             *  这里采用方式一
             */
            AVStream *oustream = avformat_new_stream(pOFormatCtx, NULL);
            if (oustream == NULL) {
                LOGD("video avformat_new_stream fail");
                continue;
            }
            // 这里可以不赋值，AVFormatContext 会自动处理 并且自动分配AVStream的index索引
            //    stream->id = pOFormatCtx->nb_streams-1;
            
            // 将instream中的参数信息拷贝过来
            avcodec_parameters_copy(oustream->codecpar, instream->codecpar);
            videoIndex_ou = oustream->index;
            success = true;
        } else if (instream->codecpar->codec_type == AVMEDIA_TYPE_AUDIO && audioIndex_ou != -1) {
            AVStream *oustream = avformat_new_stream(pOFormatCtx, NULL);
            if (oustream == NULL) {
                LOGD("audio avformat_new_stream fail");
                continue;
            }
            avcodec_parameters_copy(oustream->codecpar, instream->codecpar);
            audioIndex_ou = oustream->index;
            success = true;
        }
        
        if (success) {
            break;
        }
    }
    
    return success;
}

void Muxer::setReadVideoPacketFunc(void* client,ReadPacketFunc *readfunction)
{
    pReadVideoFunc = readfunction;
    pVideoClient = client;
}

void Muxer::setReadAudioPacketFunc(void* client,ReadPacketFunc *readfunction)
{
    pReadAudioFunc = readfunction;
    pAudioClient = client;
}

/** 封装步骤
 *  1、通过avformat_alloc_output_context2()创建输出AVFormatContext，
 *  2、给AVFormatContext添加对应的输出流(音视频流)，并且为它们赋值正确的封装格式参数
 *  3、avio_open()打开输出缓冲区 然后写入文件头信息avformat_write_header();
 *  4、写入具体的音视频数据
 *  5、写入文件尾信息完成文件保存收尾工作等等
 */
bool Muxer::openMuxer()
{
    LOGD("openMuxer()");
    if (mMuxerOpen) {
        LOGD("has openMuxer()");
        return true;
    }
    mMuxerOpen = true;
    
    AVFormatContext *vIfmtCtx = iFormatFromBuffer(pVideoClient,pReadVideoFunc);
    AVFormatContext *aIfmtCtx = iFormatFromBuffer(pAudioClient,pReadAudioFunc);
    if (!vIfmtCtx && !aIfmtCtx) {
        LOGD("没有获取到音视频流信息");
        return false;
    }
    
    if (!pOFormatCtx) {
        LOGD("pOFormatCtx is NULL");
        return false;
    }
    
    int ret = 0;
    if (vIfmtCtx) {
        if(!addNewAVStream(vIfmtCtx)){
            LOGD("addNewAVStream fail");
            return false;
        }
    }
    if (aIfmtCtx) {
        if (!addNewAVStream(aIfmtCtx)) {
            return false;
        }
    }
    
    /** 3、打开输出文件并和输出缓冲区关联起来并且写入头文件信息
     */
    if (pOFormatCtx->flags & AVFMT_NOFILE) {
        ret = avio_open(&pOFormatCtx->pb, NULL, AVIO_FLAG_READ_WRITE);
        if (ret < 0) {
            LOGD("avio_open fail %d",ret);
            return false;
        }
    }
    // 写入头文件信息
    ret = avformat_write_header(pOFormatCtx, NULL);
    if (ret < 0) {
        LOGD("avformat_write_header fail %d",ret);
        return false;
    }
    
    int64_t cur_video_pts = 0,cur_audio_pts = 0;
    bool write_video = false;
    bool write_audio = false;
    if (videoIndex_ou != -1 && audioIndex_ou == -1) {   // 只写入视频数据
        write_video = true;
        write_audio = false;
    } else if (videoIndex_ou == -1 && audioIndex_ou != -1) {    // 只写入音频数据
        write_video = false;
        write_audio = true;
    } else if (videoIndex_ou != -1 && audioIndex_ou != -1) {    // 同时写入音视频数据
        write_video = false;
        write_audio = false;
        if (av_compare_ts(cur_video_pts, vIfmtCtx->streams[videoIndex_in]->time_base, cur_audio_pts, aIfmtCtx->streams[audioIndex_in]->time_base) <= 0) {
            write_video = true;
        } else {
            write_audio = true;
        }
    }
    
    AVPacket *pkt = av_packet_alloc();
    while (mMuxerOpen) {
        
    }
    
    /** 5、写入文件尾信息，完成封装并且关闭AVIOContext缓冲区
     */
    ret = av_write_trailer(pOFormatCtx);
    if (ret < 0) {
        LOGD("av_write_trailer fail %d",ret);
    }
    
    return true;
}

void Muxer::closeMuxer()
{
    LOGD("closeMuxer()");
    mMuxerOpen = false;
}

AVFormatContext* Muxer::iFormatFromBuffer(void* client,ReadPacketFunc readFunc)
{
    if (!readFunc) {
        LOGD("readFunc NULL");
        return NULL;
    }
    
    int ret = 0;
    // 1、创建AVIOContext对象
    size_t iosize = sizeof(unsigned char)*Muxer_IO_buf_size;
    // av_mallocz()分配内存为cpu字节对齐的且会自动将所有字节初始值置为0
    unsigned char *iobuf = (unsigned char*)av_mallocz(iosize);
    /** AVIOContext它是一个输入输出的缓冲区。作为输入缓冲区，当调用av_read_frame()函数的时候会从该缓冲区中读取数据，然后该缓冲区会不停的从读取回调函数中获取数据
     *  readFunc()回调函数和av_read_frame()在同一个线程
     */
    AVIOContext *iopb = avio_alloc_context(iobuf, (int)iosize, 0, client, readFunc, NULL, NULL);
    if (!iopb) {
        LOGD("avio_alloc_context() null");
        return NULL;
    }
    
    // 2、根据AVIOContext对象传递的码流信息分析出格式然后创建AVInputFormat对象
    AVInputFormat *ifmt=NULL;
    /** 该函数根据提供的码流信息分析出格式并创建AVInputFormat对象。
     *  如果码流信息不正确或者没有获取到，则创建对象会失败 return <0
     *  调用该函数会触发调用AVIOContext的读取函数，并阻塞一段时间(若读取到指定大小字节的数据后还没有分析出码流格式则会调用失败)
     */
    /** 遇到问题：av_probe_input_buffer()函数奔溃
     *  分析原因：avio_alloc_context()函数的读取回调函数为NULL
     *  解决方案：进行异常处理
     */
    ret = av_probe_input_buffer(iopb, &ifmt, NULL, NULL, 0, 0);
    if (ret < 0) {
        LOGD("av_probe_input_buffer fail");
        return NULL;
    }
    
    // 3、创建AVFormatContext对象，并根据AVIOContext对象和AVInputFormat对象进行初始化
    AVFormatContext *returnFmt = avformat_alloc_context();
    if (!returnFmt) {
        LOGD("avformat_alloc_context NULL");
        return NULL;
    }
    returnFmt->pb = iopb;
    
    // 如果returnFmt为NULL，函数内部会自动调用avformat_alloc_context()
    ret = avformat_open_input(&returnFmt, NULL, ifmt, NULL);    // 根据AVIOContext对象进行初始化
    if (ret < 0) {
        LOGD("avformat_open_input fail");
        return NULL;
    }
    ret = avformat_find_stream_info(returnFmt, NULL);
    if (ret < 0) {
        LOGD("avformat_find_stream_info fail");
        return NULL;
    }
    
    // 4、打印一下创建的AVFormatContext格式
    LOGD("av_dump_format begin");
    av_dump_format(returnFmt, 0, NULL, 1);
    LOGD("av_dump_format end");
    
    return returnFmt;
}
