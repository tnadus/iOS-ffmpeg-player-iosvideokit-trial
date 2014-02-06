//
//  VKPlayerController.h
//  VideoKitSample
//
//  Created by Tarum Nadus on 11.10.2013.
//  Copyright (c) 2013 VideoKit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VKAVDecodeManager.h"

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

/* VKPlayer Fullscreen mode changed notifications */

///Description of notification which is posted when Player will enter fullscreen
extern NSString *kVKPlayerWillEnterFullscreenNotification;

///Description of notification which is posted when Player did enter fullscreen
extern NSString *kVKPlayerDidEnterFullscreenNotification;

///Description of notification which is posted when Player will exit fullscreen
extern NSString *kVKPlayerWillExitFullscreenNotification;

///Description of notification which is posted when Player did exit fullscreen
extern NSString *kVKPlayerDidExitFullscreenNotification;


/* VKDecoder decode option keys */

///Defining RTSP protocol transport layer. Values are predefined under "VKDecoder decode option values"
extern NSString *VKDECODER_OPT_KEY_RTSP_TRANSPORT;

///Selection of audio default stream by index. Value must be an NSNumber object. (High priority)
extern NSString *VKDECODER_OPT_KEY_AUD_STRM_DEF_IDX;

///Selection of audio default stream by string. Value must be an NSString object (normal priority)
extern NSString *VKDECODER_OPT_KEY_AUD_STRM_DEF_STR;

///FFmpeg can not determine some formats, so we force ffmpeg to use mjpeg format. Value must be @"1" which is an NSString object
extern NSString *VKDECODER_OPT_KEY_FORCE_MJPEG;

///FFmpeg has many server configuration parameters and if this key and value (value must be always @"1") is set, all parameter will pass through ffmpeg without any modification. This is like playing a url with fflay, for example, ffplay rtsp://xxx.xxx.xxx.xxx -rtsp_transport tcp
extern NSString *VKDECODER_OPT_KEY_PASS_THROUGH;

/* VKDecoder decode option values*/

///RTSP uses UDP transport layer - advantage fast, disadvantage packets can be lost
extern NSString *VKDECODER_OPT_VALUE_RTSP_TRANSPORT_UDP;

///RTSP uses TCP transport layer, advantage no packet loss, disadvantage slow when comparing with UDP
extern NSString *VKDECODER_OPT_VALUE_RTSP_TRANSPORT_TCP;

// /RTSP uses multicast UDP to retrieve packets
extern NSString *VKDECODER_OPT_VALUE_RTSP_TRANSPORT_UDP_MULTICAST;

///RTSP uses http tunnelling to retrieve packets
extern NSString *VKDECODER_OPT_VALUE_RTSP_TRANSPORT_HTTP;

/**
 *  Implement this delegate if you want to get notified about state changes with error codes of VKPlayerController
 */
@protocol VKPlayerControllerDelegate <NSObject>

@optional
/**
 *  Optional delegate method, add this method to your viewcontroller if you want to be notified
 *
 *  @param state   Indicates the state in VKDecoderState type
 *  @param errCode Indicates the error code in VKError type
 */
- (void)onPlayerStateChanged:(VKDecoderState)state errorCode:(VKError)errCode;

@end

@class VKGLES2View;


/**
 * A Player object which is subclass of NSObject, player can be used in embedded and/or fullscreen or non 
 UI. Also, more than one instance can be added in a same view without causing any problem like interfereing... Player is similar to Apple's native API "MPMovieController", so it's as easy as using the MPMovieController
 */
@interface VKPlayerController : NSObject

/**
 *  Initialization of VKPlayerController object
 *
 *  @return VKPlayerController object
 */
- (id)init;

/**
 *  Initialization of VKPlayerController object with the url string object
 *
 *  @param urlString The location of the file or remote stream url. If it's a file then it must be located either in your app directory or on a remote server
 *
 *  @return VKPlayerController object
 */
- (id)initWithURLString:(NSString *)urlString;

#pragma mark Player public control methods

/**
 *  This method plays the stream/file if urlstring is given in the initialization or content url is set
 */
- (void)play;

/**
 *  Toggle play or pause the stream/file
 */
- (void)togglePause;

/**
 *  This method stops the stream/file
 */
- (void)stop;

/**
 *  Frames are drawn on view, so scale method switches view contentmode property from UIViewContentModeScaleAspectFit to UIViewContentModeScaleAspectFill or the opposite
 */
- (void)scale;

/**
 *  Update the screen with the following video frame
 */
- (void)stepToNextFrame;

/**
 *  Set current duration in files both for located locally or located remotely
 *
 *  @param value A double value in seconds
 */
- (void)setStreamCurrentDuration:(float)value;

/**
 *  Cycle/Change to next the audio stream if remote stream/file has more than 1 audio stream
 */
- (void)changeAudioStream;

/**
 * Mute audio
 *
 * This does not have any effect on MPVolumeView or not have any relation with MPVolumeView
 * 
 * @param value If YES, audio will be muted
 */
- (void)setMute:(BOOL)value;

/** Get snapshot of glview in UIImage format
 
 Sample code to show how to save the snapshot
 
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *savedImagePath = [documentsDirectory stringByAppendingPathComponent:@"savedImage.png"];
        UIImage *image = [self snapshot];
        NSData *imageData = UIImagePNGRepresentation(image);
        [imageData writeToFile:savedImagePath atomically:NO];
 
 @return UIImage object
 */
- (UIImage *)snapshot;

#pragma mark Player UI methods

/**
 *  Make embedded player fullscreen or make fullscreen player embedded
 *
 *  @param value    Specify YES, If you want to show the player in fullscreen, does not have any effect on fullscreen player. Specify NO, If you want to show the player in embedded, does not have any effect on embedded player
 *  @param animated Specify YES If the transitions will be animated
 */
- (void)setFullScreen:(BOOL)value animated:(BOOL)animated;

///The location of the file or remote stream url in string format. If it's a file then it must be located either in your app directory or on a remote server
@property (nonatomic, retain) NSString *contentURLString;

///Streaming options according to the used protocol
@property (nonatomic, retain) NSDictionary *decoderOptions;

// /Indicates the decoder states in VKDecoderState enumerations
@property (nonatomic, readonly) VKDecoderState decoderState;

///The bar title of Video Player
@property (nonatomic, retain) NSString *barTitle;

///Set your Parent View Controller as delegate If you want to be notified for state changes
@property (nonatomic, assign) id<VKPlayerControllerDelegate> delegate;

///Specify YES to hide status bar, default is NO. Effective only in fullscreen presenting
@property (nonatomic, assign, getter=isStatusBarHidden) BOOL statusBarHidden;

///VKPlayerController view object, any custom views must be added on this
@property (nonatomic, retain, readonly) UIView *view;

///The video rendering view, opengl configuration is done to be ready for rendering
@property (nonatomic, readonly) VKGLES2View *renderView;

///The background color of player, default is black
@property (nonatomic, retain) UIColor *backgroundColor;

///An empty and transparent UIViewController used for fullscreen - embedded transitioning. Do not set it If you have a very powerful reason to do that
@property (nonatomic, assign) UIViewController *containerVc;

///Indicates the state of player presenting mode. If set, then this makes embedded player fullscreen or makes fullscreen player embedded
@property (nonatomic, assign, getter=isFullScreen) BOOL fullScreen;

///Determines the User interface of control elements on screen
@property (nonatomic, assign) VKPlayerControlStyle controlStyle;

///The time, specified in seconds within the video timeline, when playback should start
@property (nonatomic, assign) int64_t initialPlaybackTime;

///Loops movie playback <number> times. 0 means forever
@property (nonatomic, assign) int loopPlayback;

///Stop player when video is done playing
@property (nonatomic, assign) BOOL autoStopAtEnd;

///Specify YES to show video in extended screen, default is No
@property (nonatomic, assign) BOOL allowsAirPlay;



@end

