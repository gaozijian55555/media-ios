//
//  SFVideoEncoder.h
//  media
//
//  Created by 飞拍科技 on 2019/7/22.
//  Copyright © 2019 飞拍科技. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommonDefine.h"
#import "VideoParameters.h"

@interface SFVideoEncoder : NSObject

- (void)test;

- (void)setParameters:(VideoParameters*)param;
- (BOOL)sendRawVideo:(VideoFrame*)yuvframe packet:(VideoPacket*)packet;
- (BOOL)endEncode;
@end
