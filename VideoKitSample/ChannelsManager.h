//
//  ChannelsManager.h
//  VideoKitSample
//
//  Created by Murat Sudan
//  Copyright (c) 2014 iOS VideoKit. All rights reserved.
//  Elma DIGITAL
//

#import <foundation/Foundation.h>
#import "Channel.h"

@interface ChannelsManager : NSObject

+ (id)sharedManager;

- (void)updateChannelList;

@property(nonatomic, readonly) NSMutableArray *streamList;
@property(nonatomic, readonly) NSMutableArray *fileList;
@property(nonatomic, readonly) NSMutableArray *recordList;

@end
