//
//  FFmpegEnDecodeViewController.m
//  media
//
//  Created by 飞拍科技 on 2019/8/9.
//  Copyright © 2019 飞拍科技. All rights reserved.
//

#import "FFmpegEnDecodeViewController.h"
#import "VideoDecoder.h"
#import "VideoEncoder.h"

@interface FFmpegEnDecodeViewController ()

@end

@implementation FFmpegEnDecodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    VideoDecoder *decoder = [[VideoDecoder alloc] init];
    [decoder test];
    
    VideoEncoder *encoder = [[VideoEncoder alloc] init];
    [encoder test];
    // Do any additional setup after loading the view.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
