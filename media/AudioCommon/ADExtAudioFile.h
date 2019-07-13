//
//  ADExtAudioFile.h
//  media
//
//  Created by 飞拍科技 on 2019/7/4.
//  Copyright © 2019 飞拍科技. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioCommon.h"

/** 对ExtAudioFileRef读写的封装
 *  1、ExtAudioFile 是AudioUnit的一个组件，它提供了将原始音频数据编码为WAV，caff等编码格式的音频数据，同时提供写入文件的接口
 *  2、同时它还提供了从文件中读取数据解码为PCM音频数据的功能
 *  3、编码和解码支持硬编解码和软编解码
 */
@interface ADExtAudioFile : NSObject
{
    NSString *_filePath;
    // 用于读写文件的文件句柄
    ExtAudioFileRef _audioFile;
    
    // 用于写
    AudioStreamBasicDescription _outabsdForWriter;
    AudioStreamBasicDescription _fileDataabsdForWriter;
    
    // 用于读
    AudioStreamBasicDescription _clientabsdForReader;
    AudioStreamBasicDescription _fileDataabsdForReader;
}

/** 用于读文件
 *  path:要读取文件的路径
 *  outabsd:从文件中读取数据后的最终输出格式
 *  repeat:当到达文件的末尾后，是否重新开始读取
 */
- (id)initWithReadPath:(NSString*)path adsb:(AudioStreamBasicDescription)outabsd canrepeat:(BOOL)repeat;
- (OSStatus)readFrames:(UInt32*)framesNum toBufferData:(AudioBufferList*)bufferlist;


// 用于写文件
- (id)initWithWritePath:(NSString*)path adsb:(AudioStreamBasicDescription)inabsd;
- (OSStatus)writeFrames:(UInt32*)framesNum toBufferData:(AudioBufferList*)bufferlist;

- (void)closeFile;
@end
