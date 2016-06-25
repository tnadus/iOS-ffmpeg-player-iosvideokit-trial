//
//  VKAVDecodeManager.h
//  VideoKit
//
//  Created by Murat Sudan
//  Copyright (c) 2014 iOS VideoKit. All rights reserved.
//  Elma DIGITAL
//

#import "VKDecodeManager.h"

@interface VKAVDecodeManager : VKDecodeManager

/**
 *  Initialize Audio Video decoder
 *  @param username - If license-form is not accessible, fill this parameter with your username taken from our server
 *  @param secret   - If license-form is not accessible, fill this parameter with your secret taken from our server
 *  @return VKAVDecodeManager object
 */
- (id)initWithUsername:(NSString *)username secret:(NSString *)secret;

@end
