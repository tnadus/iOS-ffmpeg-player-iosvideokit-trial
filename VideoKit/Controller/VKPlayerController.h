//
//  VKPlayerController.h
//  VideoKit
//
//  Created by Murat Sudan
//  Copyright (c) 2014 iOS VideoKit. All rights reserved.
//  Elma DIGITAL
//

#import <UIKit/UIKit.h>
#import "VKPlayerControllerBase.h"

/**
 * Determines the User interface of control elements on screen
 *
 * VKPlayerControlStyle enums are
 * - kVKPlayerControlStyleNone        > Shows only Video screen, no bar, no panel, no any user interface component
 * - kVKPlayerControlStyleEmbedded    > Shows small User interface elements on screen
 * - kVKPlayerControlStyleFullScreen  > Shows full width bar and a big control panel on screen
 */
typedef enum {
    kVKPlayerControlStyleNone,
    kVKPlayerControlStyleEmbedded,
    kVKPlayerControlStyleFullScreen
} VKPlayerControlStyle;

@interface VKPlayerController : VKPlayerControllerBase

- (id)init;

/**
 *  Initialization of VKPlayerControllerBase object with the url string object
 *
 *  @param urlString The location of the file or remote stream url. If it's a file then it must be located either in your app directory or on a remote server
 *
 *  @return VKPlayerControllerBase object
 */
- (id)initWithURLString:(NSString *)urlString;

///Determines the User interface of control elements on screen
@property (nonatomic, assign) VKPlayerControlStyle controlStyle;

@end

