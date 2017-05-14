//
//  VideoFrame.h
//  VideoKit
//
//  Created by Murat Sudan
//  Copyright (c) 2014 iOS VideoKit. All rights reserved.
//  Elma DIGITAL
//

#import <Foundation/Foundation.h>
#import "VKDecodeManager.h"
#import "VKColorPlane.h"

/**
 *  Videos are consist of many still images and when those images are shown rapidly, then the animation will be come out. VKVideoFrame holds all data of one of the still images. Please note that the data is in raw format (not encoded)
 *  
 */
@interface VKVideoFrame : NSObject

/**
 *  Create a VKVideoFrame object & initialize it
 *
 *  @return VKVideoFrame object
 */
- (id) init;

///Frame's width retrieved from AVCodecContext
@property(nonatomic, assign) int width;

///Frame's height retrieved from AVCodecContext
@property(nonatomic, assign) int height;

///Ratio is not always width/height, some streams are using special aspect ratios and this property holds this ratio
@property(nonatomic, assign) float aspectRatio;

///The presenting timestamp of frame based on stream's time base
@property(nonatomic, assign) double pts;

///holds the byte position of AVPacket in stream, used for AV syncing
@property(nonatomic, assign) int64_t pos;

///Serial is used for identifying the packet queues of stream
@property(nonatomic, assign) int serial;

///States whether the frame is interlaced or not
@property(nonatomic, assign) BOOL interlaced;

@end
