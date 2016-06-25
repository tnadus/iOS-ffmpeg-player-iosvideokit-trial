//
//  VKDecoder.h
//  VideoKit
//
//  Created by Murat Sudan
//  Copyright (c) 2014 iOS VideoKit. All rights reserved.
//  Elma DIGITAL
//

#import <Foundation/Foundation.h>
#import "VKDecodeManager.h"
#import "VKQueue.h"

#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include "libswresample/swresample.h"
#include <libavutil/opt.h>
#include <pthread.h>

@class VKClock;

/**
 *  Base class of VKAudioDecoder & VKVideoDecoder classes. It holds common ffmpeg related datas such as CodecContext, AVCodec, etc...
 */
@interface VKDecoder : VKQueue {
    AVCodecContext* _codecContext;
    AVCodec* _codec;
    AVStream* _stream;
    NSInteger _streamId;
    
    //managers
    id _manager;
    id _clockManager;
    
    int _ffmpegVersMajor;
    VKClock *_decoderClock;
}

/* init with codec context */
/**
 *  Initialize VKDecoder with AVCodecContext, AVStream, stream index, and manager parameters
 *
 *  @param cdcCtx  FFmpeg's codec I/O context
 *  @param strm    FFmpeg's Stream structure
 *  @param sId     Stream index
 *  @param manager VKDecodeManager object
 *
 *  @return VKDecoder object
 */
- (id)initWithCodecContext:(AVCodecContext*)cdcCtx stream:(AVStream *)strm streamId:(NSInteger)sId manager:(id)manager;

///The stream index in streams list in FFmpeg
@property (nonatomic, readonly) NSInteger streamId;

///VKDecodeManager object, used for retrieving global states
@property (nonatomic, readonly) id manager;

@property (nonatomic, readonly) VKClock *decoderClock;

@end
