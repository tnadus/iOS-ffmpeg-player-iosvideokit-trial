//
//  ChannelsManager.h
//  VideoKitSample
//
//  Created by Tarum Nadus on 26.10.2013.
//  Copyright (c) 2013 VideoKit. All rights reserved.
//

#import <foundation/Foundation.h>
#import "Channel.h"

@interface ChannelsManager : NSObject

+ (id)sharedManager;

@property(nonatomic, readonly) NSMutableArray *streamList;
@property(nonatomic, readonly) NSMutableArray *fileList;

@end
