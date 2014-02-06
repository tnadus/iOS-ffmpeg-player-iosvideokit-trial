//
//  VKGLES2View.m
//  VideoKit
//
//  Created by Tarum Nadus on 30.05.2013.
//  Copyright (c) 2013 Tarum Nadus. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VKDecodeManager;
@class VKVideoFrame;

/**
 *  VideoKit uses opengl framework to render pictures & make color conversion fastly. VKGLES2View is a subclass of UIView and its opengl settings are ready for opengl rendering.
 */
@interface VKGLES2View : UIView

#pragma mark - public methods

/**
*  Initialize openGL view with DecodeManager
*
*  @param decoder VKDecodeManager object to be feed from
*
*  @return 0 for succes and non-zero for failure
*/
- (int)initGLWithDecodeManager:(VKDecodeManager *)decoder;

/**
 *  Enable-disable retina frames if device has retina support, default is YES
 *
 *  @param value Specify YES for enabling or NO for disabling Retina
 */
- (void)enableRetina:(BOOL)value;

/** 
 * Get snapshot of glview in UIImage format
 *
 * @return UIImage object
 */
- (UIImage *)snapshot;

/**
 *  update the openGL screen with new frame
 *
 *  @param vidFrame needs VKVideoFrame object to draw screen
 */
- (void)updateScreenWithFrame:(VKVideoFrame *)vidFrame;

/**
 *  destroy openGL view
 */
- (void)shutdown;

@end
