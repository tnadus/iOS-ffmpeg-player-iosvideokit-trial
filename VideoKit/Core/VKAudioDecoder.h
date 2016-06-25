//
//  VKAudioDecoder.h
//  VideoKit
//
//  Created by Murat Sudan
//  Copyright (c) 2014 iOS VideoKit. All rights reserved.
//  Elma DIGITAL
//

#import <Foundation/Foundation.h>
#import "VKDecoder.h"

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
- (id)initWithFormatContext:(AVFormatContext*)avFmtCtx codecContext:(AVCodecContext*)cdcCtx
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
 *  Start AUGraph
 */
- (void)startAUGraph;

/**
 *  Stop AUGraph
 */
- (void)stopAUGraph;

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

/**
 * This is a channel panning effect which must be between -1.0 (all audio is routed to left channel)
 * and +1.0 (all audio is routed to right channel),
 * default value is 0.0 which means no panning (audio is routed to both left & right channels)
 */
@property (nonatomic, assign) float panningLevel;

@end
