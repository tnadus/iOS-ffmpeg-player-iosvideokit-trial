//
//  VKVideoFrameRGB.h
//  VideoKitSample
//
//  Created by Murat Sudan on 14/04/16.
//  Copyright © 2016 iosvideokit. All rights reserved.
//

#import "VKVideoFrame.h"

/**
 * VKVideoFrameYUVVT is subclass of VKVideoFrame class to hold PixelBuffer data
 */
@interface VKVideoFrameYUVVT : VKVideoFrame

///PixelBuffer object that holds raw video data coming from VideoToolbox decoder
@property (nonatomic, assign) CVPixelBufferRef pixelBuffer;

@end
