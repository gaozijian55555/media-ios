//
//  VideoEncoder.m
//  media
//
//  Created by 飞拍科技 on 2019/7/22.
//  Copyright © 2019 飞拍科技. All rights reserved.
//

#import "VideoEncoder.h"
#include "VideoCodecEncoder.hpp"

@implementation VideoEncoder
{
    VideoCodecEncoder *_encoder;
}

- (void)test
{
    _encoder = new VideoCodecEncoder();
}
@end
