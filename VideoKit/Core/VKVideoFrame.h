//
//  VideoFrame.h
//  MMSTv
//
//  Created by Tarum Nadus on 6/17/12.
//  Copyright (c) 2013-2014 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VKDecodeManager.h"

/**
 *  A data class that holds video frames's color data and data size
 */
@interface VSColorPlane : NSObject

///Frame's color data size
@property (nonatomic, assign) int size;

///Frame's color data
@property (nonatomic, assign) UInt8 *data;

@end

/**
 *  Videos are consist of many still images and when those images are shown rapidly, then the animation will be come out. VKVideoFrame holds all data of one of the still images. Please note that the data is in raw format (not encoded) and the color space is YUV
 *  
 */
@interface VKVideoFrame : NSObject {
    int width;
    int height;
    double pts;                                  ///< presentation time stamp for thispicture
    double duration;                             ///< expected duration of the frame
    int64_t pos;                                 ///< byte position in file
    int serial;
    float aspectRatio;
    
    //RGB color space
    VSColorPlane *_pRGB;
    
    //YUV color space
    VSColorPlane *_pLuma;
    VSColorPlane *_pChromaB;
    VSColorPlane *_pChromaR;
}

/**
 *  Create a VKVideoFrame object with the specified color format
 *
 *  @param format VKVideoFrameColorFormatYUV or VKVideoFrameColorFormatRGB are supported
 *
 *  @return VKVideoFrame object
 */
- (id) initWithColorFormat:(VKVideoStreamColorFormat) format;

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

///VSColorPlane object that holds data for Red, Green, Blue colors of image for RGB
@property (nonatomic, assign) VSColorPlane *pRGB;

///VSColorPlane object that holds data for brightness of image for YUV format
@property (nonatomic, assign) VSColorPlane *pLuma;

///VSColorPlane object that holds data for color of image for YUV format
@property (nonatomic, assign) VSColorPlane *pChromaB;

///VSColorPlane object that holds data for color of image for YUV format
@property (nonatomic, assign) VSColorPlane *pChromaR;


@end
