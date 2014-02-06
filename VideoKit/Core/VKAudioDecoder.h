//
//  VKAudioDecoder.h
//  VideoKit
//
//  Created by Tarum Nadus on 11/16/12.
//  Copyright (c) 2013-2014 VideoKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VKDecoder.h"
#import "VKDecodeManager.h"

/**
 *  VKAudioDecoder is responsible for decoding & resampling of audio packets, and making audio effects
 */
@interface VKAudioDecoder : VKDecoder {
    BOOL _waitingForPackets;
}

/**
 *  Initialize VKAudioDecoder object with AVCodecContext, AVStream, stream, and index parameters
 *
 *  @param cdcCtx       FFmpeg's codec I/O context
 *  @param strm         FFmpeg's Stream structure
 *  @param sId          Stream index
 *  @param manager      VKDecodeManager object
 *
 *  @return VKAudioDecoder object
 */
- (id)initWithCodecContext:(AVCodecContext*)cdcCtx
stream:(AVStream *)strm streamId:(NSInteger)sId manager:(id)manager;

/**
 *  Shutdown audio decoder
 */
- (void)shutdown;

/**
 *  Queues are interworking with eachother and uses wait mechanism for management, this methods unlocks all queues
 */
- (void)unlockQueues;

/**
 *  Indicates the last Audio packet's presenting timestamp value based on stream's time base
 *
 *  @return pts (presenting time stamp) * stream->time_base
 */
- (double)audioClock;

/**
 *  Start Audio Unit
 */
- (void)startUnit;

/**
 *  Stop Audio Unit
 */
- (void)stopUnit;

/**
 *  Start Audio Subsystem
 */
- (void)startAudioSystem;

/**
 *  Stop Audio Subsystem
 */
- (void)stopAudioSystem;

/**
 *  Inform Audio Decoder that it's reached end of file
 *
 *  @param value Specify YES for end of file is reached or NO for continue playing
 */
- (void)setEOF:(BOOL)value;

///Buffering is based on whather the queue has audio packets or not, so this property indicates this state
@property (nonatomic, readonly) BOOL isWaitingForPackets;

///Time difference of current PTS value and now
@property (nonatomic, readonly) double currentPtsDrift;

///Current byte position of AVPacket in stream, used for AV syncing
@property (nonatomic, readonly) int64_t currentPos;

///This a gain volume effect which must be between 0.0 - 1.0, default value is 1.0

/**
 * This a gain volume effect which must be between 0.0 - 1.0, default value is 1.0
 *
 * volumeLevel does not have any effect on MPVolumeView
 */
@property (nonatomic, assign) float volumeLevel;

///AudioUnit subsystem instance
- (AudioComponentInstance)audioUnit;

@end
