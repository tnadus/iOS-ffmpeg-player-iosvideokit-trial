//
//  VKRecorder.h
//  VideoKit
//
//  Created by Murat Sudan
//  Copyright (c) 2014 iOS VideoKit. All rights reserved.
//  Elma DIGITAL
//

#import <Foundation/Foundation.h>
#import "VKQueue.h"

#include <libavformat/avformat.h>
#include <libavformat/avio.h>

typedef NS_ENUM(NSUInteger, VKErrorRecorder) {
    kVKErrorRecorderNone,
    kVKErrorRecorderOnInitialization,
    kVKErrorRecorderOnWriting,
    kVKErrorRecorderOther,
};

@protocol VKRecorderDelegate;

/**
 *  VKRecorder is responsible for writing the encoded packets, as they are (no transcoding), to the file
 */

@interface VKRecorder : VKQueue

#pragma mark - Funtion declerations

/**
 *  Initialize Recorder with the input streams's format context and optional output file name
 *
 *  @param fmtCtx Input streams's format context
 *  @param path   Optional, this is the path where recorded stream will be saved, If, it's set to NULL, then default path which is tmp folder under home directory will be used.
 *
 *  @return VKRecorder object
 */
- (id)initWithInputFormat:(AVFormatContext *)fmtCtx activeAudioStreamId:(int)aStreamId
      activeVideoStreamId:(int)vStreamId fullPathWithFileName:(NSString *)path;

///Start recording functionality
- (void)start;

///Stop recording functionality
- (void)stop;

///Holds the path of file of recorded stream
@property (nonatomic, readonly) NSString *recordPath;

///Some MJPEG streams don't have any PTS value, this property helps to set the interval between 2 frame, default is 30
@property (nonatomic, assign) int timeMultiplierForMJPEG;

///Delegate object is notified about the status of recording
@property (nonatomic, assign) id<VKRecorderDelegate> delegate;

@end

@protocol VKRecorderDelegate <NSObject>

@optional
/**
 *  Optional delegate method, notifies the delegate object about the start event of recording functionality
 *
 *  @param recorder   Holds the recorder object
 */
- (void)didStartRecordingWithRecorder:(VKRecorder *)recorder;

/**
 *  Optional delegate method, notifies the delegate object about the stop event of recording functionality with error status (success or error)
 *
 *  @param recorder   Holds the pointer of recorder object
 *  @param error   If no error, it's set to kVKErrorRecorderNone, otherwise it's set to an appropriate error
 */
- (void)didStopRecordingWithRecorder:(VKRecorder *)recorder error:(VKErrorRecorder)error;

@end

