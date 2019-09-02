//
//  VideoParameters.m
//  media
//
//  Created by apple on 2019/8/24.
//  Copyright © 2019 飞拍科技. All rights reserved.
//

#import "VideoParameters.h"

@implementation VideoParameters

- (id)initWithWidth:(NSInteger)width
             height:(NSInteger)height
        pixelformat:(MZPixelFormat)pixelformat
                fps:(NSInteger)fps
                gop:(NSInteger)gop
            bframes:(NSInteger)bframes
            bitrate:(NSInteger)brate
{
    if (self = [super init]) {
        self.width = (int)width;
        self.height = (int)height;
        self.format = pixelformat;
        self.fps = (int)fps;
        self.GOP = (int)gop;
        self.maxBFrameNums = (int)bframes;
        self.bitRate = (int)brate;
    }
    
    return self;
}
@end
