//
//  AudioDataWriter.m
//  media
//
//  Created by 飞拍科技 on 2019/6/26.
//  Copyright © 2019 飞拍科技. All rights reserved.
//

#import "AudioDataWriter.h"

@implementation AudioDataWriter

- (void)deletePath:(NSString*)path
{
    if (path.length == 0) {
        return;
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]){
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
}

- (void)writeDataBytes:(Byte*)dBytes len:(NSInteger)len toPath:(NSString *)savePath
{
    NSData *data = [NSData dataWithBytes:dBytes length:len];
    [self writeData:data toPath:savePath];
}
- (void)writeData:(NSData*)data toPath:(NSString *)savePath
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:savePath]){
        [[NSFileManager defaultManager] createFileAtPath:savePath contents:nil attributes:nil];
    }
    
    NSFileHandle * handle = [NSFileHandle fileHandleForWritingAtPath:savePath];
    [handle seekToEndOfFile];
    [handle writeData:data];
}
@end
