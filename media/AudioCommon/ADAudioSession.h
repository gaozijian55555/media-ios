//
//  ADAudioSession.h
//  media
//
//  Created by Owen on 2019/5/19.
//  Copyright © 2019 Owen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

/** 该类是对AVAudioSession的封装
 *
 */
@interface ADAudioSession : NSObject

@property (strong, nonatomic) AVAudioSession *aSession;
@property (assign, nonatomic) CGFloat   currentSampleRate;
@property (assign, nonatomic) NSInteger currentChannels;

@property (assign, nonatomic) AudioFormatFlags formatFlags;
@property (assign, nonatomic) AudioFormatID    formatId;

-(instancetype)initWithCategary:(AVAudioSessionCategory)category channels:(NSInteger)chs sampleRate:(double)rate bufferDuration:(NSTimeInterval)duration formatFlags:(AudioFormatFlags)flags formatId:(AudioFormatID)formatId;

// 是否planner 存储方式
- (BOOL)isPlanner;
// 每个声道占用的字节数，对于IOS来说，只有32位的采样格式，所以这里返回4
- (int)bytesPerChannel;
@end
