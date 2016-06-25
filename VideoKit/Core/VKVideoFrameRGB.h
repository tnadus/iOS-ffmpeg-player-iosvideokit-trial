//
//  VKVideoFrameRGB.h
//  VideoKitSample
//
//  Created by Murat Sudan on 14/04/16.
//  Copyright © 2016 iosvideokit. All rights reserved.
//

#import "VKVideoFrame.h"

/**
 * VKVideoFrameRGB is subclass of VKVideoFrame class to hold RGB data
 */
@interface VKVideoFrameRGB : VKVideoFrame

///VKColorPlane object that holds data for Red, Green, Blue colors of image for RGB
@property (nonatomic, assign) VKColorPlane *pRGB;

@end
