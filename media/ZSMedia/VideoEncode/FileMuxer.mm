//
//  Muxer.m
//  media
//
//  Created by apple on 2019/9/8.
//  Copyright © 2019 飞拍科技. All rights reserved.
//

#import "FileMuxer.h"

#include <pthread.h>
#include <vector>
#include "Muxer.hpp"

#define Max_Vector_size 20
using namespace std;
int read_video_packet(void*clientData,uint8_t*buf,int buflen);
int read_audio_packet(void*clientData,uint8_t*buf,int buflen);

@implementation FileMuxer
{
    NSString *_savepath;
    pthread_mutex_t _videomutex;
    pthread_mutex_t _audiomutex;
    std::vector<VideoPacket*>_videopkts;
    std::vector<VideoPacket*>_audiopkts;
    
    Muxer   *_muxer;
}

- (instancetype)initWithPath:(NSString*)filepath
{
    if (self = [super init]) {
        
        NSAssert(filepath !=nil, @"存储路径不能为空");
        
        _savepath = filepath;
        // 创建普通锁，当一个线程加锁以后，其余请求锁的线程将形成一个等待队列，并在解锁后按优先级获得锁。
        pthread_mutex_init(&_videomutex, NULL);
        pthread_mutex_init(&_audiomutex, NULL);
        
        
    }
    
    return self;
}

- (BOOL)openMuxer
{
    if (_muxer) {
        return YES;
    }
    
    _muxer = new Muxer([_savepath UTF8String]);
    _muxer->setReadVideoPacketFunc((__bridge void*)self,read_video_packet);
    
    
    return _muxer->openMuxer()?YES:NO;
}

- (BOOL)canWriteVideo
{
    BOOL canwrite = NO;
    pthread_mutex_lock(&_videomutex);
    canwrite = _videopkts.size() >= Max_Vector_size;
    pthread_mutex_unlock(&_videomutex);
    
    return canwrite;
}

- (void)writeVideoPacket:(VideoPacket*)packet
{
    pthread_mutex_lock(&_videomutex);
    unsigned long size = _videopkts.size();
    if (size >= Max_Vector_size) {
        LOGD("writeVideoPacket has > Max_Vector_size");
        pthread_mutex_unlock(&_videomutex);
        return;
    }
    _videopkts.push_back(packet);
    pthread_mutex_unlock(&_videomutex);
}

- (BOOL)canWriteAudio
{
    BOOL canwrite = NO;
    pthread_mutex_lock(&_audiomutex);
    canwrite = _audiopkts.size() >= Max_Vector_size;
    pthread_mutex_unlock(&_audiomutex);
    
    return YES;
}

- (void)writeAudioPacket
{
    
}

- (void)finishWrite
{
    if (_muxer) {
        _muxer->closeMuxer();
        delete _muxer;
        _muxer = NULL;
    }
}


int read_video_packet(void*clientData,uint8_t*buf,int buflen)
{
    
    // 非NSObject指针对象到NSobject对象的转换
    FileMuxer *mySelf = (__bridge FileMuxer*)clientData;
    
    int count = (int)mySelf->_videopkts.size();
    if (count <= 0) {
        return 0;
    }
    
    VideoPacket *packet = *(mySelf->_videopkts.begin());
    mySelf->_videopkts.erase(mySelf->_videopkts.begin());
    
    int size = packet->size;
    memcpy(buf, packet->data, size);
    
    delete [] packet->data;
    delete packet;
    
    return size;
}

int read_audio_packet(void*clientData,uint8_t*buf,int buflen)
{
    return 0;
}

@end
