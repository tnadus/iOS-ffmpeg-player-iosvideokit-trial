//
//  VKDecoder.h
//  VideoKit
//
//  Created by Tarum Nadus on 31.12.2013-2014.
//  Copyright (c) 2013-2014 VideoKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include "libswresample/swresample.h"
#include <libavutil/opt.h>
#include <pthread.h>

/**
 *  Base class of VKAudioDecoder & VKVideoDecoder classes. It holds common ffmpeg related datas such as CodecContext, AVCodec, etc...
 */
@interface VKDecoder : NSObject {
    AVCodecContext* _codecContext;
    AVCodec* _codec;
    AVStream* _stream;
    NSInteger _streamId;

    NSMutableArray *_pktQueue;/* queue including encoded data packets */
    long _pktQueueSize; /** queue size */

    //mutex
    pthread_mutex_t _mutexPkt;
    pthread_cond_t _condPkt;

    //manager
    id _manager;

    AVPacket _flushPkt;
    int _queueSerial;
    int _abortRequest;
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

/**
 *  Queues are interworking with eachother and uses wait mechanism for management, this methods unlocks all queues
 */
- (void)unlockQueues;

/**
 *  Adds raw data media packet
 *
 *  @param packet FFmpeg's AVPacket structured object is needed
 */
- (void)addPacket:(AVPacket*)packet;

/**
 *  Adds a special packet to flush queues
 */
- (void)addFlushPkt;

/**
 *  Clear buffers
 */
- (void)clearPktQueue;

///Mutex for managing packet processing priority
- (pthread_mutex_t*)mutexPkt;

///Condition for managing packet processing priority
- (pthread_cond_t*)condPkt;

///A mutable array that holds VKPacket objects
@property (nonatomic, readonly) NSMutableArray *pktQueue;

///The size of pktQueue array
@property (nonatomic, readonly) long pktQueueSize;

///The stream index in streams list in FFmpeg
@property (nonatomic, readonly) NSInteger streamId;

///VKDecodeManager object, used for retrieving global states
@property (nonatomic, readonly) id manager;

///A special property to stop all jobs to kill decoder properly
@property (nonatomic, assign) int abortRequest;

@end
