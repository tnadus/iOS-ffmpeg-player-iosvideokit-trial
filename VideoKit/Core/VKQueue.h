//
//  VKQueue.h
//  VideoKit
//
//  Created by Murat Sudan
//  Copyright (c) 2014 iOS VideoKit. All rights reserved.
//  Elma DIGITAL
//

#import <Foundation/Foundation.h>
#import "VKPacket.h"

#include <libavcodec/avcodec.h>
#include <pthread.h>

/**
 *  Manages the packet qeueue
 */

@interface VKQueue : NSObject {
    NSMutableArray *_pktQueue;/* queue including encoded data packets */
    long _pktQueueSize; /** queue size */
    
    //mutex & conditional
    pthread_mutex_t _mutexPkt;
    pthread_cond_t _condPkt;
    
    AVPacket _flushPkt;
    int _queueSerial;
    int _abortRequest;
}

/**
 *  Queues are interworking with eachother and uses wait/signal mechanism for management, this methods unlocks all queues
 */
- (void)unlockQueues;

/**
 *  Adds encoded data media packet
 *
 *  @param packet FFmpeg's AVPacket structured object is needed
 */
- (void)addPacket:(AVPacket*)packet;

/**
 *  Adds a special packet to flush queues
 */
- (void)addFlushPkt;

/**
 *  Adds an empty packet to queue
*/
- (void)addEmptyPkt;

/**
 *  Remove last pkt from queue
 */
- (void)removeLastPkt;

/**
 *  Remove pkt at index from queue
 */
- (void)removePktAtIndex:(unsigned int)index;

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

///A special property to stop all working jobs
@property (nonatomic, assign) int abortRequest;


@end
