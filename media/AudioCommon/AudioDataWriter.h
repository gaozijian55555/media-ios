//
//  AudioDataWriter.h
//  media
//
//  Created by 飞拍科技 on 2019/6/26.
//  Copyright © 2019 飞拍科技. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioDataWriter : NSObject

- (void)deletePath:(NSString*)path;

- (void)writeDataBytes:(Byte*)dBytes len:(NSInteger)len toPath:(NSString *)savePath;
- (void)writeData:(NSData*)data toPath:(NSString *)savePath;
@end
