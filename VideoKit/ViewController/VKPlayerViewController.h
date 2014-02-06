//
//  VKPlayerViewController.h
//  VideoKit
//
//  Created by Tarum Nadus on 11/16/12.
//  Copyright (c) 2013-2014 VideoKit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VKPlayerController.h"

/**
 *  Implement this delegate if you want to get notified about state changes with error codes
 */
@protocol VKPlayerViewControllerDelegate <NSObject>
@optional

/**
 *  Optional delegate method, add this method to your viewcontroller if you want to be notified
 *
 *  @param state   Indicates the state in VKDecoderState type
 *  @param errCode Indicates the error code in VKError type
 */
- (void)onPlayerViewControllerStateChanged:(VKDecoderState)state errorCode:(VKError)errCode;
@end


/**
 * A Player object which is subclass of UIViewController, it's useful for showing video in full screen in a easy and practical way like Apple's native API "MPMovieViewController"
 */
@interface VKPlayerViewController : UIViewController

/**
* Init Player View Controller with url & protocol options. For ex: rtsp protocol has transport layer options, this can be used like below [NSDictionary dictionaryWithObject:@"udp" forKey:@"rtsp_transport"] for more info please see http://iosvideokit/documentation/#RTSP_OPTIONS
*
*  @param urlString The location of the file or remote stream url. If it's a file then it must be located either in your app directory or on a remote server
*  @param options   Streaming options according to the used protocol
*
*  @return VKPlayerViewController object
*/
- (id)initWithURLString:(NSString *)urlString decoderOptions:(NSDictionary *)options;

///The bar title of Video Player
@property (nonatomic, retain) NSString *barTitle;

///Specify YES to hide status bar, default is NO
@property (nonatomic, assign, getter=isStatusBarHidden) BOOL statusBarHidden;

///Set your Parent View Controller as delegate If you want to be notified for state changes of VKPlayerViewController
@property (nonatomic, assign) id<VKPlayerViewControllerDelegate> delegate;

///Specify YES to show video in extended screen, default is NO
@property (nonatomic, assign) BOOL allowAirPlay;
@end
