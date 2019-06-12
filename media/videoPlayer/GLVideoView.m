//
//  GLVideoView.m
//  media
//
//  Created by 飞拍科技 on 2019/6/8.
//  Copyright © 2019 飞拍科技. All rights reserved.
//

#import "GLVideoView.h"
#import "GLDefine.h"
#import "GLContext.h"
#import "GLProgram.h"
#import "GLRenderYUVSource.h"

NSString *const comvs = SHADER_STRING
(
 attribute vec4 position;
 attribute vec2 texcoord;
 
 varying highp vec2 tex_coord;
 
 void main(){
     gl_Position = position;
     tex_coord = texcoord;
 }
 );

// 获取一张图片的颜色
NSString *const comfs = SHADER_STRING
(
 uniform sampler2D texture;
 
 varying highp vec2 tex_coord;
 
 void main(){
     gl_FragColor = texture2D(texture,tex_coord);
 }
 );

const float compositions[8] = {
    -1.0,-1.0,
    1.0,-1.0,
    -1.0,1.0,
    1.0,1.0
};
const float comtexcoords[8] = {
    0.0,0.0,
    1.0,0.0,
    0.0,1.0,
    1.0,1.0
};

@interface GLVideoView ()
{
    GLuint _renderbuffer;
}
@property (strong, nonatomic)GLContext *context;
@property (strong, nonatomic)GLRenderYUVSource *yuvSource;
@property (strong, nonatomic)GLProgram *renderProgram;
@end
@implementation GLVideoView
+ (Class)layerClass;
{
    return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        CAEAGLLayer *layer = (CAEAGLLayer*)self.layer;
        self.context = [[GLContext alloc] initDefaultContextLayer:layer];
        [self.context useAsCurrentContext];
        
        self.yuvSource = [[GLRenderYUVSource alloc] initWithContext:self.context];
        self.renderProgram = [[GLProgram alloc] initWithVertexShaderType:comvs fragShader:comfs];
    }
    
    return self;
}


- (void)setupRenderbuffer
{
    glGenRenderbuffers(1, &_renderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderbuffer);
    [self.context.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
}
- (void)rendyuvFrame:(VideoFrame*)yuvFrame
{
    if (yuvFrame == NULL) {
        return;
    }
    
    // 上传纹理
    [self.yuvSource loadYUVFrame:yuvFrame];
    
    // 渲染
    [self.yuvSource renderpass];
    
    // 呈现到屏幕上
    [self.context presentForDisplay];
}
@end
