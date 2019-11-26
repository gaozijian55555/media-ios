//
//  Muxer.h
//  media
//
//  Created by apple on 2019/9/8.
//  Copyright © 2019 飞拍科技. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "XRZCommonDefine.h"

@interface FileMuxer : NSObject

- (instancetype)initWithPath:(NSString*)filepath;

- (BOOL)openMuxer;

- (BOOL)canWriteVideo;
- (void)writeVideoPacket:(VideoPacket*)packet;

- (BOOL)canWriteAudio;
- (void)writeAudioPacket;

- (void)finishWrite;
@end
