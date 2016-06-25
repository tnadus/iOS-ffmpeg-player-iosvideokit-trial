//
//  VKClock.h
//  VideoKitSample
//
//  Created by Murat Sudan on 13/09/15.
//  Copyright (c) 2015 iosvideokit. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    kVKClockTypeAudio = 1,
    kVKClockTypeVideo,
    kVKClockTypeExternal
} VKClockType;


@interface VKClock : NSObject

- (id)initWithType:(VKClockType)type;

- (int*)serialPtr;

@property(nonatomic, assign) double pts;           /* clock base */
@property(nonatomic, assign) double ptsDrift;     /* clock base minus time at which we updated the clock */
@property(nonatomic, assign) double last_updated;
@property(nonatomic, assign) double speed;
@property(nonatomic, assign) int serial;           /* clock is based on a packet with this serial */
@property(nonatomic, assign) int paused;
@property(nonatomic, assign) int *queueSerial;
@property (nonatomic, readonly) VKClockType type;

@end
