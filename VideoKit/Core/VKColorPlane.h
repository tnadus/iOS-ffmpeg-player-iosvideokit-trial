//
//  VKColorPlane.h
//  VideoKitSample
//
//  Created by Murat Sudan on 14/04/16.
//  Copyright © 2016 iosvideokit. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  A data class that holds video frames's color data and data size
 */
@interface VKColorPlane : NSObject

///Frame's color data size
@property (nonatomic, assign) int size;

///Frame's color data
@property (nonatomic, assign) UInt8 *data;

@end
