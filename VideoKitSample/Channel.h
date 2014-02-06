//
//  VKChannel.h
//  VideoKitSample
//
//  Created by Tarum Nadus on 12.10.2013.
//  Copyright (c) 2013 VideoKit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Channel : NSObject {
    NSString *_name;
    NSString *_urlAddress;
    NSString *_description;
    BOOL _localFile;
    NSDictionary *_options;
}

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *urlAddress;
@property (nonatomic, readonly) NSString *description;
@property (nonatomic, readonly) NSDictionary *options;
@property (nonatomic, readonly) BOOL localFile;

+ (id)channelWithName:(NSString *)name addr:(NSString *)addr description:(NSString *)description localFile:(BOOL)localFile options:(NSDictionary *)options;
- (id)initWithName:(NSString *)name addr:(NSString *)addr description:(NSString *)description localFile:(BOOL)localFile options:(NSDictionary *)options;

@end
