//
//  VKClockManager.h
//  VideoKitSample
//
//  Created by Murat Sudan on 18/09/15.
//  Copyright (c) 2015 iosvideokit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VKClock.h"

//Audio & Video sync tresholds
/* no AV sync correction is done if below the minimum AV sync threshold */
#define AV_SYNC_THRESHOLD_MIN 0.01
/* AV sync correction is done if above the maximum AV sync threshold */
#define AV_SYNC_THRESHOLD_MAX 0.1
/* If a frame duration is longer than this, it will not be duplicated to compensate AV sync */
#define AV_SYNC_FRAMEDUP_THRESHOLD 0.1
/* no AV correction is done if too big error */
#define AV_NOSYNC_THRESHOLD 10.0

extern int64_t av_gettime(void);

@interface VKClockManager : NSObject

- (id)init;

- (void)initClock:(VKClock *)clock serial:(int *)serial;
- (void)setPts:(double)pts serial:(int)serial clock:(VKClock *)clock;
- (void)setTime:(double)time pts:(double)pts serial:(int)serial clock:(VKClock *)clock;
- (void)setSpeed:(double)speed clock:(VKClock *)clock;
- (double)clockTime:(VKClock *)clock;
- (void)setClockTime:(VKClock *)clock pts:(double)pts serial:(int)serial;
- (void)syncClockToSlave:(VKClock *)clock slave:(VKClock *)slaveClock;
@end
