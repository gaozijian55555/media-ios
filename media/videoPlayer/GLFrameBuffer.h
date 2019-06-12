//
//  GLFrameBuffer.h
//  OpenGLES-ios
//
//  Created by 飞拍科技 on 2019/6/5.
//  Copyright © 2019 飞拍科技. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreMedia/CoreMedia.h>
#import "GLContext.h"
#import <VideoToolbox/VideoToolbox.h>

typedef struct GLFrameBufferTextureOptions {
    GLenum minFilter;
    GLenum magFilter;
    GLenum wrapS;
    GLenum wrapT;
    GLenum internalFormat;
    GLenum format;
    GLenum type;
} GLFrameBufferTextureOptions;

GLFrameBufferTextureOptions defaultOptionsForTexture(void);

/** 对FBO帧缓冲区的封装
 *  1、如果使用CVOpenGLESTextureCacheRef来管理texture，则不需要手动创建texture
 */
@interface GLFrameBuffer : NSObject
// 用于表示纹理的长宽
@property (nonatomic,readonly) CGSize size;
@property (nonatomic,readonly) GLContext *context;
@property (nonatomic,readonly) GLuint texture;  // 纹理id
@property (nonatomic,readonly) GLFrameBufferTextureOptions textureOptions;

// 将默认创建一个1280x720大小的FBO
- (id)initDefaultBufferWithContext:(GLContext*)context;
- (id)initWithContext:(GLContext*)context bufferSize:(CGSize)size;
- (void)destroyFramebuffer;

- (void)activateFramebuffer;

// 将FBO中的像素数据转化成图片对象返回
- (CGImageRef)newCGImageFromFramebufferContents;
@end
