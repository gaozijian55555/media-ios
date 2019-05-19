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
@end
