//
//  MyPacket.h
//  VideoKit
//
//  Created by Murat Sudan
//  Copyright (c) 2014 iOS VideoKit. All rights reserved.
//  Elma DIGITAL
//

#import <Foundation/Foundation.h>
#include <libavcodec/avcodec.h>

/**
 *  VKPacket is an objective-c class of AVPacket structure, but holds only needed properties of AVPacket structure
 */
@interface VKPacket : NSObject

/**
 *  Initialize a VKPacket object
 *
 *  @param pkt    FFmpeg's structure that stores compressed data, typically exported by demuxers
 * and then passed as input to decoders
 *  @param serial The identifying number of queue inside stream
 *  @param flush  Flush packet is a special packet and if this value is YES then queues will be flushed
 *  @return VKPacket object
 */
- (id) initWithPkt:(AVPacket *) pkt serial:(int) serial isFlush:(BOOL) flush;

///The size of data holded in VKPacket
@property (nonatomic, readonly) int size;

///Encoded data in int16_t format
@property (nonatomic, readonly) NSData *samples;

///The presenting time stamp of packet
@property (nonatomic, readonly) double pts;

///The decoding time stamp of packet
@property (nonatomic, readonly) double dts;

///The duration of packet
@property (nonatomic, assign) int64_t duration;

///The modified presenting time stamp of packet, used for recording
@property (nonatomic, assign) double modifiedPts;

///The modified decoding time stamp of packet, used for recording
@property (nonatomic, assign) double modifiedDts;

///The modified duration of packet, used for recording
@property (nonatomic, assign) int64_t modifiedDuration;

///The byte position of packet in stream
@property (nonatomic, readonly) int64_t pos;

///Serial is used for identifying the packet queues of stream
@property (nonatomic, readonly) int serial;

///Indicates whether if the packet is a special flush packet or not
@property (nonatomic, readonly) BOOL flush;

///Indicates that the packet belongs to Audio, Video or other stream
@property (nonatomic, readonly) int streamIndex;

///Indicates flags of AVPacket
@property (nonatomic, readonly) int flags;

@end
