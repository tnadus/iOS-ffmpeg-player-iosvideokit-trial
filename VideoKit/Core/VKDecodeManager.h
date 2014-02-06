//
//  VKDecodeManager.h
//  VideoKit
//
//  Created by Tarum Nadus on 11/16/12.
//  Copyright (c) 2013-2014 VideoKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#include <libavcodec/avcodec.h>

#define TRIAL  1

#pragma mark
//Language properties
#ifndef RTL
#define TR(A) NSLocalizedString((A), @"")
#else
#define TR(A) [NSLocalizedString((A), @"") stringReversed]
#endif

#ifndef NS_BLOCK_ASSERTIONS
#define NS_BLOCK_ASSERTIONS
#endif

//defines
//Audio & Video sync tresholds
#define AV_SYNC_THRESHOLD                           0.01
#define AV_NOSYNC_THRESHOLD                         10.0

typedef enum {
    VKVideoStreamColorFormatUnknown = 0,
    VKVideoStreamColorFormatYUV,
    VKVideoStreamColorFormatRGB
} VKVideoStreamColorFormat;

#pragma mark
///Log definitions & levels
typedef enum {
	kVKLogLevelDisable = 0,
	kVKLogLevelStateChanges = 1,
	kVKLogLevelDecoder = 2,
	kVKLogLevelDecoderExtra = 4,
    kVKLogLevelOpenGL = 8,
	kVKLogLevelAVSync = 16,
	kVKLogLevelAll = 31,
} VKLogLevel;

extern VKLogLevel log_level;

#define VKLog(A, ...) do {  \
                            if (A <= log_level) { \
                                NSLog(__VA_ARGS__);\
                            } \
                    } while (0)


///Stream info data keys
extern NSString *STREAMINFO_KEY_CONNECTION;
extern NSString *STREAMINFO_KEY_DOWNLOAD;
extern NSString *STREAMINFO_KEY_BITRATE;
extern NSString *STREAMINFO_KEY_AUDIO;
extern NSString *STREAMINFO_KEY_VIDEO;


///Video Stream Error enumerations
typedef enum {
    kVKErrorNone = 0,
    kVKErrorUnsupportedProtocol,
    kVKErrorStreamURLParseError,
    kVKErrorOpenStream,
    kVKErrorStreamInfoNotFound,
    kVKErrorStreamsNotAvailable,
    kVKErrorStreamDurationNotFound,
    kVKErrorAudioStreamNotFound,
    kVKErrorVideoStreamNotFound,
    kVKErrorAudioCodecNotFound,
    kVKErrorVideoCodecNotFound,
    kVKErrorAudioCodecNotOpened,
    kVKErrorUnsupportedAudioFormat,
    kVKErrorAudioStreamAlreadyOpened,
    kVKErrorVideoCodecNotOpened,
    kVKErrorAudioAllocateMemory,
    kVKErrorVideoAllocateMemory,
    kVKErrorStreamReadError,
    kVKErrorStreamEOFError,
    kVKErroSetupScaler,
} VKError;

///Decoder state enumerations
typedef enum {
    kVKDecoderStateNone = 0,
    kVKDecoderStateConnecting,
    kVKDecoderStateConnected,
    kVKDecoderStateConnectionFailed,
    kVKDecoderStateGotStreamDuration,
    kVKDecoderStateGotAudioStreamInfo,
    kVKDecoderStateGotVideoStreamInfo,
    kVKDecoderStateInitialLoading,
    kVKDecoderStateReadyToPlay,
    kVKDecoderStateBuffering,
    kVKDecoderStatePlaying,
    kVKDecoderStatePaused,
    kVKDecoderStateStoppedByUser,
    kVKDecoderStateStoppedWithError,
} VKDecoderState;

enum {
    AV_SYNC_AUDIO_MASTER, /* default choice */
    AV_SYNC_VIDEO_MASTER,
    AV_SYNC_EXTERNAL_CLOCK, /* synchronize to an external clock */
};

@protocol VKDecoderDelegate;

/**
 *  VKDecodeManager is the authority of core engine part of VideoKit. VKDecodeManager is responsible for the management of Audio & Video decoders, management of connection and reading packets from stream or file. Also, VKPlayerController communicates VKDecoderManager to do non-UI actions and configurations.
 */
@interface VKDecodeManager : NSObject {
    unsigned long _totalBytesDownloaded;
    NSMutableDictionary *_streamInfo;
    
    NSObject<VKDecoderDelegate> *_delegate;
}

#pragma mark - Funtion declerations

/**
 *  Initialize decoder
 *
 *  @return VKDecodeManager object
 */
- (id)init;

/**
 *  Connect to stream URL String with decode options
 *
 *  @param urlString The location of the file or remote stream url. If it's a file then it must be located either in your app directory or on a remote server.
 *  @param options   Streaming options according to the used protocol
 *
 *  @return kVKErrorNone If success otherwise kVKError typed error
 */
- (VKError)connectWithStreamURLString:(NSString*)urlString options:(NSDictionary *)options;

/**
 *  Toggle play & pause the stream/file
 */
- (void)streamTogglePause;

/**
 *  This represents the master clock (audio clock)
 *
 *  @return audio clock time if audio stream exists otherwise video clock time
 */
- (double)masterClock;

/**
 *  AV syncing diff between audio & video clock
 *
 *  @return a stream->time_base based number
 */
- (double)clockDifference;

/**
 *  Set log levels accourding to the VKLogLevel enums
 *
 *  @param logLevel Filter or expand the log mechanism, values are VKLogLevel enumerations
 */
- (void)setLogLevel:(VKLogLevel)logLevel;

/* External clock sync  */

/**
 *  External clock sync, only mastering to audio is implemented
 *
 *  @param pts The presenting time stamp
 */
- (void)checkExternalClockSync:(double)pts;

/**
 *  Check External clock speed and update it if necessary
 */
- (void)checkExternalClockSpeed;

/**
 *  Sync audio and video with mastering one of them, only mastering to audio is implemented
 *
 *  @return Enumeration of sync types
 */
- (int)masterSyncType;

/**
 *  Detects whether if the stream is realtime or not
 *
 *  @return YES if the stream is realtime otherwise NO
 */
- (BOOL)isRealTime;

#pragma mark - Public Actions

/**
 *  Toggle play or pause the stream/file
 */
- (void)togglePause;

/**
 *  Update the screen with the following video frame
 */
- (void)stepToNextFrame;

/**
 *  abort method stops/unlock all waiting threads/queues
 *
 *  Before stoping the decoder, abort must be called.
 */
- (void)abort;

/**
 *  stop method shuts down the decoder
 *
 * abort must be called before stop method to kill decoder safely
 */
- (void)stop;

/**
 *  Seek in files both for located locally or located remotely
 *
 *  @param value A double value in seconds
 */
- (void)doSeek:(double)value;

/**
 *  Seek in buffered data coming from streaming server
 *
 *  This is a special method for realtime communication, it reduces the latency in realtime streaming
 *
 *  @param value Set a float value between 0.0 and 1.0. 1.0 means the end of the buffered data
 */
- (void)seekInDedoderBufferByValue:(float)value;

/**
 *  Cycle/Change to next the audio stream if remote stream/file has more than 1 audio stream
 */
- (void)cycleAudioStream;

/**
 *  Change to desired audio stream with index if remote stream/file has more than 1 audio stream
 *
 *  @param index Index of audio stream
 */
- (void)cycleAudioStreamWithStreamIndex:(int) index;

/**
 *  Provides information of codecs used in stream/file
 *
 *  @param index Index of stream
 *
 *  @return Information in NSString format
 */
- (NSString *)codecInfoWithStreamIndex:(int) index;

/**
 *  Provides the list of playable video streams
 *
 *  @return The list of playable video streams in NSArray format
 */
- (NSArray *)playableVideoStreams;

/**
 *  Provides the list of playable audio streams
 *
 *  @return The list of playable audio streams in NSArray format
 */
- (NSArray *)playableAudioStreams;

/**
 *  Updates the information of codecs used in stream/file for a stream
 *
 *  @param index     Index of the stream
 *  @param mediaType MediaType in AVMediaType enumerations
 */
- (void)updateStreamInfoWithSelectedStreamIndex:(int)index type:(int)mediaType;


#pragma mark - Audio interruption handling

#pragma mark iOS 5.x

///AVAudioSession beginInterruption handler
- (void)beginInterruption;

//AVAudioSession endInterruptionWithFlags handler with flags
- (void)endInterruptionWithFlags:(NSUInteger)flags;

#pragma mark iOS 6.x or higher Audio interruption handling

//AVAudioSession interruption handler with notification
- (void) interruption:(NSNotification*)notification;

#pragma mark - Variable declerations

///If set, then delegate class instance will get all state change events of VKDecodeManager
@property (nonatomic, assign) NSObject<VKDecoderDelegate> *delegate;

@property (nonatomic, readonly) VKVideoStreamColorFormat videoStreamColorFormat;

///Indicates whether the decoder is paused or not
@property (nonatomic, readonly) BOOL streamIsPaused;

///Indicates whether any abort action is requested
@property (nonatomic, readonly) int abortIsRequested;

///Indicates the maximum frame duration, used in AV sync
@property (nonatomic, readonly) double maxFrameDuration;

///An integer value that indicates the action of showing the next video frame
@property (nonatomic, readonly) int step;

///Holds return code of av_read_pause FFmpeg API, used in AV sync
@property (nonatomic, readonly) int readPauseCode;

///Frame's width retrieved from AVCodecContext
@property (nonatomic, readonly) NSUInteger frameWidth;

///Frame's height retrieved from AVCodecContext
@property (nonatomic, readonly) NSUInteger frameHeight;

///Holds the state of application, used for not updating opengl view if app is in background
@property (nonatomic, readonly) BOOL appIsInBackgroundNow;

///Holds the total bytes that streamed from network
@property (nonatomic, readonly) unsigned long totalBytesDownloaded;

///Information that holds current audio and video stream and codecs
@property (nonatomic, readonly) NSMutableDictionary *streamInfo;

/**
 *  A readonly value that indicates the total duration
 *
 *  This value is valid for only files, live streams do not have duration information
 */
@property (nonatomic, readonly) float durationInSeconds;

///Size of data to probe, useful for reducing connection duration
@property (nonatomic, assign) int probeSize;

///Maximum time (in AV_TIME_BASE units) during which the input should be analyzed in avformat_find_stream_info()
@property (nonatomic, assign) int maxAnalyzeDuration;

/**
 *  Specify YES for better file streaming
 *
 *  Live streaming and remote file streaming needs some fine-tuning, so set this value YES for better remote file streaming
 */
@property (nonatomic, assign) BOOL remoteFileStreaming;

///The size of decoded pictures queue, for using to limit memory usage, default is 4
@property (nonatomic, assign) int videoPictureQueueSize;

///The size of queues in bytes of both Audio & Video encoded packets, for using to limit memory usage, default is 15 * 1024* 1024
@property (nonatomic, assign) int maxQueueSize;

///Get packets till this number then start playing, higher value increases buffering time, default is 15
@property (nonatomic, assign) int minFramesToStartPlaying;

///Shows audio's, and video's clocks difference logs for a specified interval, default is 0.01
@property (nonatomic, assign) float avSyncLogFrequency;

///Shows read packets count from a stream for a specific interval, default is 0.001
@property (nonatomic, assign) float avPacketCountLogFrequency;

///Disable audio stream, default is NO
@property (nonatomic, assign) BOOL audioIsDisabled;

///The time, specified in seconds within the video timeline, when playback should start
@property (nonatomic, assign) int64_t initialPlaybackTime;

///Loops movie playback given times. 0 means forever
@property (nonatomic, assign) int loopPlayback;

///Stop decoder when video is done playing
@property (nonatomic, assign) BOOL autoStopAtEnd;

/**
 * This is a gain volume effect which must be between 0.0 - 1.0, default value is 1.0
 *
 * volumeLevel does not have any effect on MPVolumeView or not have any relation with MPVolumeView
 */
@property (nonatomic, assign) float volumeLevel;

@end

/**
 *  Implement this delegate if you want to get notified about state changes with error codes of VKDecodeManager
 */
@protocol VKDecoderDelegate<NSObject>
@required

/**
 *  Required delegate method, If delegate object is set
 *
 *  @param state   Indicates the state in VKDecoderState type
 *  @param errCode Indicates the error code in VKError type
 */
- (void)decoderStateChanged:(VKDecoderState)state errorCode:(VKError)errCode;
@end

