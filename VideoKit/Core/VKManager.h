//
//  VKManager.h
//  VideoKitSample
//
//  Created by Murat Sudan on 11/07/14.
//  Copyright (c) 2014 iosvideokit. All rights reserved.
//


#ifndef VK_CORE_BINARY
#define VK_RECORDING_CAPABILITY          @"recording_feature_is_enabled"
#endif

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifdef VK_RECORDING_CAPABILITY
#import "VKRecorder.h"
#endif

#include <libavcodec/avcodec.h>
#include <config.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libavutil/opt.h>

#include "cmdutils.h"

#define TRIAL                            1

#define VK_CLIENT_VERSION                @"2.6"

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
    kVKErrorAudioCodecOptNotFound,
    kVKErrorVideoCodecNotOpened,
    kVKErrorVideoCodecOptNotFound,
    kVKErrorAudioAllocateMemory,
    kVKErrorVideoAllocateMemory,
    kVKErrorStreamReadError,
    kVKErrorStreamEOFError,
    kVKErroSetupScaler,
} VKError;

@interface VKManager : NSObject {
    BOOL _debugBuild;
    BOOL _trialBuild;
}


- (id)initWithUsername:(NSString *)username secret:(NSString *)secret;

- (void)initEngine;

- (AVFormatContext *)allocateContext;

- (int)startConnectionWithContext:(AVFormatContext **)avCtx fileName:(const char *)avName avInput:(AVInputFormat *)avFmt
                          options:(AVDictionary **)avOptions userOptions:(AVDictionary **)avUserOptions;

- (VKError)parseOptionsFromURLString:(NSString *)urlString
                      finalURLString:(NSString **)finalURLString;

- (BOOL)willAbort;

- (void)abort;

@end
