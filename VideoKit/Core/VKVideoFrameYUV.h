//
//  VKVideoFrameYUV.h
//  VideoKitSample
//
//  Created by Murat Sudan on 14/04/16.
//  Copyright © 2016 iosvideokit. All rights reserved.
//

#import "VKVideoFrame.h"

/**
 * VKVideoFrameYUV is subclass of VKVideoFrame class to hold YUV data
 */
@interface VKVideoFrameYUV : VKVideoFrame

///VKColorPlane object that holds data for brightness of image for YUV format
@property (nonatomic, readonly) VKColorPlane *pLuma;

///VKColorPlane object that holds data for color of image for YUV format
@property (nonatomic, readonly) VKColorPlane *pChromaB;

///VKColorPlane object that holds data for color of image for YUV format
@property (nonatomic, readonly) VKColorPlane *pChromaR;

@end
