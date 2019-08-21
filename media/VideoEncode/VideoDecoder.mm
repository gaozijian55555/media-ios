//
//  VideoDecoder.m
//  media
//
//  Created by 飞拍科技 on 2019/7/22.
//  Copyright © 2019 飞拍科技. All rights reserved.
//

#import "VideoDecoder.h"
#include "VideoCodecEncoder.hpp"

@implementation VideoDecoder
{
    VideoCodecEncoder   *_decoder;
}

- (void)test
{
    _decoder = new VideoCodecEncoder();
    
}
@end
