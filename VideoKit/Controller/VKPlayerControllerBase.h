//
//  VKPlayerControllerBase.h
//  VideoKit
//
//  Created by Murat Sudan
//  Copyright (c) 2014 iOS VideoKit. All rights reserved.
//  Elma DIGITAL
//

#import <UIKit/UIKit.h>
#import "VKAVDecodeManager.h"
#import "VKScrollViewContainer.h"

typedef struct VKPlayerCustomIO {
    ///The customIO descriptor to hold custom IO data pointer.
    void *customIODescriptor;
    
    ///The customIO total size to be used for moving pointer on custom IO descriptor
    size_t customIOSize;
    
    ///The customIO last byte read index to be used for moving pointer on custom IO descriptor
    unsigned long lastByteIndex;
    
    ///The data used for passing argument to read_data method callback
    void *opaque;
    
} VKPlayerCustomIO ;

@class VKPlayerControllerBase;

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

/**
 *  Defining RTSP protocol transport layer. Values are predefined under "VKDecoder decode option values"
 *
 *  The value corresponding to the key is passed to ffmpeg. 
 *  Important: This key-value is effectiveless when VKDECODER_OPT_KEY_PASS_THROUGH key is set in decoder options.
 */
extern NSString *VKDECODER_OPT_KEY_RTSP_TRANSPORT;

///Selection of audio default stream by index. Value must be an NSNumber object. (High priority)
extern NSString *VKDECODER_OPT_KEY_AUD_STRM_DEF_IDX;

///Selection of audio default stream by string. Value must be an NSString object (normal priority)
extern NSString *VKDECODER_OPT_KEY_AUD_STRM_DEF_STR;

/**
 *  FFmpeg can not determine some formats, so we force ffmpeg to use mjpeg format. 
 *  Value must be @"1" which is an NSString object
 *
 *  The value corresponding to the key is passed to ffmpeg.
 *  Important: This key-value is effectiveless when VKDECODER_OPT_KEY_PASS_THROUGH key is set in decoder options.
 */
extern NSString *VKDECODER_OPT_KEY_FORCE_MJPEG;

/**
 *  FFmpeg has many server configuration parameters and if this key and value (value must be always @"1") 
 *  is set, all parameter will pass through ffmpeg without any modification. This is like playing a url with
 *  fflay, for example, ffplay rtsp://xxx.xxx.xxx.xxx -rtsp_transport tcp
 *
 *  The value corresponding to the key is passed to ffmpeg.
 *  Important: When VKDECODER_OPT_KEY_PASS_THROUGH key is set in decoder options, other parameters that passes to ffmpeg are effectiveless.
 */
extern NSString *VKDECODER_OPT_KEY_PASS_THROUGH;

/**
 *  Caching mechanism using ffmpeg cache protocol, If this option is used, then It's possible to make Youtube
 *  like caching for http file streams. Corresponding value for this key must be set to @(1) or @"1" 
 *  object to enable this option
 *
 *  The value corresponding to the key is passed to ffmpeg.
 *  Important: This key-value is effectiveless when VKDECODER_OPT_KEY_PASS_THROUGH key is set in decoder options.
 */
extern NSString *VKDECODER_OPT_KEY_CACHE_STREAM_ENABLE;

///Set corresponding value to @1 to disable using hardware audio acceleration for specific audio codecs (MP3, AAC, etc, see docs for whole list)
extern NSString *VKDECODER_OPT_KEY_HW_ACCEL_DISABLED_AUDIO;

///Set corresponding value to @1 to disable using hardware video acceleration for h264 Video codec.
extern NSString *VKDECODER_OPT_KEY_HW_ACCEL_DISABLED_VIDEO;

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
 *  Implement this delegate if you want to get notified about state changes with error codes of VKPlayerControllerBase
 */
@protocol VKPlayerControllerDelegate <NSObject>

@optional
/**
 *  Optional delegate method, add this method to your viewcontroller if you want to be notified about player state changes
 *
 *  @param player  The player object that owns the notification
 *  @param state   Indicates the state in VKDecoderState type
 *  @param errCode Indicates the error code in VKError type, If success, returning error is kVKErrorNone
 */
- (void)player:(VKPlayerControllerBase *)player didChangeState:(VKDecoderState)state errorCode:(VKError)errCode;

#ifdef VK_RECORDING_CAPABILITY
/**
 *  Optional delegate method, add this method to your viewcontroller if you want to be notified about the start of recording functionality
 *
 *  @param player  The player object that owns the notification
 *  @param recordPath   Indicates the path of recorded file
 */
- (void)player:(VKPlayerControllerBase *)player didStartRecordingWithPath:(NSString *)recordPath;

/**
 *  Optional delegate method, add this method to your viewcontroller if you want to be notified about the stop of recording functionality
 *
 *  @param player  The player object that owns the notification
 *  @param recordPath   Indicates the path of recorded file
 *  @param error Indicates the error in VKErrorRecorder type, If success, returning error is kVKErrorRecorderNone
 */
- (void)player:(VKPlayerControllerBase *)player didStopRecordingWithPath:(NSString *)recordPath error:(VKErrorRecorder)error;
#endif

@end

/**
 *  Implement this delegate if you want to provide custom I/O data to ffmpeg, it's very useful when decoding a(n) audio/video stream in memory
 */
@protocol VKPlayerCustomIODelegate <NSObject>

@required
/**
 *  Required delegate method, add this method to your viewcontroller to provide A/V stream data to ffmpeg
 *
 *  @param player  The player object that owns the notification
 *  @param data   Indicates the data pointer to be filled
 *  @param size Indicates the size of the data pointer to be filled
 */
- (int)player:(VKPlayerControllerBase *)player ioStreamRead:(uint8_t *)data size:(int)size;

@optional

/**
 *  Optional delegate method, add this method to your viewcontroller to be able to seek in your A/V stream
 *
 *  @param player  The player object that owns the notification
 *  @param offset   Indicates the offset bytes of data
 *  @param whence Indicates the size of the data pointer to be filled
 *  Important : Even if You don't want to implement A/V stream seeking functionality, this method must be implemented with a "-1" return value
 */
- (int64_t)player:(VKPlayerControllerBase *)player ioStreamSeek:(uint64_t)offset whence:(int)whence;

/**
 *  Optional delegate method, this method is a helper method and it's good for including the custom opening socket/file etc. code and this method must return 0 for successful opening
 *  @param player  The player object that owns the notification
 */
- (VKError)ioStreamOpenForPlayer:(VKPlayerControllerBase *)player;

/**
 *  Optional delegate method, this method is a helper method and it's good for including the custom closing socket/file etc. code
 *  @param player  The player object that owns the notification
 */
- (void)ioStreamCloseForPlayer:(VKPlayerControllerBase *)player;

@end


@class VKGLES2View;
@class VKStreamInfoView;
@class VKPlayerControllerDelegate;
@class VKPlayerCustomIODelegate;

// function returning error text depending on error code
NSString * errorText(VKError errCode);

/**
 * A Player object which is subclass of NSObject, player can be used in embedded and/or fullscreen or non
 UI. Also, more than one instance can be added in a same view without causing any problem like interfereing... Player is similar to Apple's native API "MPMovieController", so it's as easy as using the MPMovieController
 */

@interface VKPlayerControllerBase : NSObject {

    //Volume control
    float _volumeLevel;
    BOOL _mute;
    BOOL _audioSessionActive;
    
    //UI elements
    VKStreamInfoView *_viewInfo;
    UIImageView *_imgViewAudioOnly;
    
    UIColor *_backgroundColor;
    
    UIView *_view;
    VKGLES2View *_renderView;
    
    //Status & tool bar properties
    NSString *_streamName;
    BOOL _sliderDurationCurrentTouched;
    
    //Gesture recognizers
    UITapGestureRecognizer *_doubleTapGestureRecognizer;
    UITapGestureRecognizer *_singleTapGestureRecognizer;
    
    //Timers & timer controls
    BOOL _panelIsHidden;
    NSTimer *_timerPanelHidden;
    
    NSTimer *_timerElapsedTime;
    int _elapsedTime;
    
    NSTimer *_timerInfoViewUpdate;
    
    NSTimer *_timerDuration;
    float _durationCurrent;
    float _durationTotal;
    
    //Container & screens
    UIViewController *_containerVc;
    BOOL _mainScreenIsMobile;
    BOOL _allowsAirPlay;
    
    //stream related
    NSString *_contentURLString;
    VKAVDecodeManager *_decodeManager;
    NSDictionary *_decodeOptions;
    VKDecoderState _decoderState;
    
    //for controlling play/stop actions
    dispatch_queue_t _playStopQueue;
    
    //snapshot
    BOOL _snapshotReadyToGet;
    
#ifdef VK_RECORDING_CAPABILITY
    //Recording functionality
    BOOL _recordingEnabled;
#endif
    
    BOOL _fullScreen;
    int64_t _initialPlaybackTime;
    int _loopPlayback;
    BOOL _autoStopAtEnd;
    BOOL _showPictureOnInitialBuffering;
    BOOL _fillScreen;
    
    //Status bar properties
    BOOL _statusBarHiddenBefore;
    BOOL _statusBarHidden;
    NSString *_staturBarInitialText;
    
    NSString *_username;
    NSString *_secret;
    
    id<VKPlayerControllerDelegate> _delegate;
    
    id<VKPlayerCustomIODelegate> _customIODelegate;
    
    VKScrollViewContainer *_scrollView;
}

/**
 *  Initialization of VKPlayerControllerBase object
 *
 *  @return VKPlayerControllerBase object
 */
- (id)initBase;

/**
 *  Initialization of VKPlayerControllerBase object with the url string object
 *
 *  @param urlString The location of the file or remote stream url. If it's a file then it must be located either in your app directory or on a remote server
 *
 *  @return VKPlayerControllerBase object
 */
- (id)initWithURLString:(NSString *)urlString;

#pragma mark Player private control methods

/**
 *  This method creates UI elements in the center of the screen
 */
- (void)createUICenter;

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
- (void)zoomInOut:(UITapGestureRecognizer *)sender;

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

/**
 * Set player's volume level
 *
 * This does not have any effect on MPVolumeView or not have any relation with MPVolumeView
 *
 * @param value must be between 0.0 & 1.0, when value is 0.0, player is muted, default is 1.0
 */
- (void)setVolumeLevel:(float)value;

/**
 *  Retreive all audio streams in stream
 */
- (NSArray *)playableAudioStreams;

/**
 *  Retreive all videos streams in stream
 */
- (NSArray *)playableVideoStreams;

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

/** Get snapshot from video stream in original size in UIImage format 
 
 It's slower than getting snapshot from glview
 
 Sample code to show how to save the snapshot
 
 NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
 NSString *documentsDirectory = [paths objectAtIndex:0];
 NSString *savedImagePath = [documentsDirectory stringByAppendingPathComponent:@"savedImage.png"];
 UIImage *image = [self snapshot];
 NSData *imageData = UIImagePNGRepresentation(image);
 [imageData writeToFile:savedImagePath atomically:NO];
 
 @return UIImage object
 */
- (UIImage *)snapshotOriginalSize;

#ifdef VK_RECORDING_CAPABILITY

/**
 *  Start recording file/network stream
 */
- (void)startRecording;

/**
 *  Stop recording file/network stream
 */
- (void)stopRecording;
#endif

/**
 *  Stops duration Timer
 */
- (void)stopDurationTimer;

/**
 *  Starts duration Timer
 */
- (void)startDurationTimer;

/**
 *  Starts elapsed Timer
 */
- (void)startElapsedTimer;

/**
 *  Stops elapsed Timer
 */
- (void)stopElapsedTimer;

#pragma mark Timers callbacks

/**
 *  Timer callback when the elapsed timer is fired
 *
 *  @param timer    NSTimer object instance for elapsed timer
 */
- (void)onTimerElapsedFired:(NSTimer *)timer;


#pragma mark Player UI methods

/**
 *  Show/Hide control panel on the screen
 *
 *  @param show    Specify YES, If you want to show control panel components on the screen. Specify NO, If you want to hide control panel components.
 *  @param expire Specify YES, If you want the control panel to hide after a certain amount of time
 */
- (void)showControlPanel:(BOOL)show willExpire:(BOOL)expire;

/**
 *  Make embedded player fullscreen or make fullscreen player embedded
 *
 *  @param value    Specify YES, If you want to show the player in fullscreen, does not have any effect on fullscreen player. Specify NO, If you want to show the player in embedded, does not have any effect on embedded player
 *  @param animated Specify YES If the transitions will be animated
 */
- (void)setFullScreen:(BOOL)value animated:(BOOL)animated;

// Shows an information view about the file currently playing
- (void)showInfoView;

// Hides the information view about the file currently playing
- (void)hideInfoView;

#pragma mark - Player UI elements

///The location of the file or remote stream url in string format. If it's a file then it must be located either in your app directory or on a remote server
@property (nonatomic, retain) NSString *contentURLString;

///Streaming options according to the used protocol
@property (nonatomic, retain) NSDictionary *decoderOptions;

///Indicates the decoder states in VKDecoderState enumerations
@property (nonatomic, readonly) VKDecoderState decoderState;

///The bar title of Video Player
@property (nonatomic, retain) NSString *barTitle;

///Set your Parent View Controller as delegate If you want to be notified for state changes
@property (nonatomic, assign) id<VKPlayerControllerDelegate> delegate;

///Set your Parent View Controller as delegate If you want to be provide custom I/O data to ffmpeg, it's very useful when decoding a(n) audio/video stream in memory
@property (nonatomic, assign) id<VKPlayerCustomIODelegate> customIODelegate;

///Specify YES to hide status bar, default is NO. Effective only in fullscreen presenting
@property (nonatomic, assign, getter=isStatusBarHidden) BOOL statusBarHidden;

///A text shown when first loading media stream/file.
@property (nonatomic, readonly) NSString *staturBarInitialText;

///VKPlayerControllerBase view object, any custom views must be added on this
@property (nonatomic, retain, readonly) UIView *view;

///The video rendering view, opengl configuration is done to be ready for rendering
@property (nonatomic, readonly) VKGLES2View *renderView;

///The scroll view for render view, scrollview helps render view zoom & scroll to anywhere in video frame
@property (nonatomic, readonly) VKScrollViewContainer *scrollView;

///The background color of player, default is black
@property (nonatomic, retain) UIColor *backgroundColor;

///An empty and transparent UIViewController used for fullscreen - embedded transitioning. Do not set it If you have a very powerful reason to do that
@property (nonatomic, assign) UIViewController *containerVc;

///Indicates the state of player presenting mode. If set, then this makes embedded player fullscreen or makes fullscreen player embedded
@property (nonatomic, assign, getter=isFullScreen) BOOL fullScreen;

///The time, specified in seconds within the video timeline, when playback should start
@property (nonatomic, assign) int64_t initialPlaybackTime;

///Loops movie playback <number> times. 0 means forever
@property (nonatomic, assign) int loopPlayback;

///Stop player when video is done playing
@property (nonatomic, assign) BOOL autoStopAtEnd;

///Specify YES to show video in extended screen, default is No
@property (nonatomic, assign) BOOL allowsAirPlay;

///Indicates the active screen is mobile or not. (If not using airplay or TV connection with cable, this value is always YES)
@property (nonatomic, readonly) BOOL mainScreenIsMobile;

///Specify YES to show first video picture during the initial buffering, default is NO
@property (nonatomic, assign) BOOL showPictureOnInitialBuffering;

///Specify YES to fit video frames fill to the player view, default is NO
@property (nonatomic, assign) BOOL fillScreen;

///Specify YES to setup VideoKit AVAudioSession property also suitable for microphone capturing, default is NO. (this property is effectiveless in tvOS platform)
@property (nonatomic, assign) BOOL allowsMicCapturing;

///Specify YES to enable providing custom I/O data to ffmpeg, it's very useful when decoding a(n) audio/video stream in memory, default is NO
@property (nonatomic, assign) BOOL enableCustomIO;

///This is a helper struct for implementing custom IO feature. Please see the struct details for more info.
@property (nonatomic, readonly) struct VKPlayerCustomIO *customIO;

#ifdef VK_RECORDING_CAPABILITY
///Specify YES to enable recording functionality, default is NO
@property (nonatomic, assign, getter = isRecordingEnabled) BOOL recordingEnabled;
#endif

#pragma mark License management properties

///If license-form is not accessible, fill this parameter with your username taken from our server
@property (nonatomic, retain) NSString *username;

///If license-form is not accessible, fill this parameter with your secret taken from our server
@property (nonatomic, retain) NSString *secret;

@end

