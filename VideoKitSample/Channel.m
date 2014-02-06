//
//  VKChannel.m
//  VideoKitSample
//
//  Created by Tarum Nadus on 12.10.2013.
//  Copyright (c) 2013 VideoKit. All rights reserved.
//

#import "Channel.h"

@implementation Channel

@synthesize name = _name;
@synthesize urlAddress = _urlAddress;
@synthesize description = _description;
@synthesize options = _options;
@synthesize localFile = _localFile;

+ (id)channelWithName:(NSString *)name addr:(NSString *)addr description:(NSString *)description localFile:(BOOL)localFile options:(NSDictionary *)options {
    return [[[self alloc] initWithName:name addr:addr description:description localFile:localFile options:options] autorelease];
}

- (id)initWithName:(NSString *)name addr:(NSString *)addr description:(NSString *)description localFile:(BOOL)localFile options:(NSDictionary *)options {
    self = [super init];
    if (self) {
        _name = [name retain];
        _urlAddress = [addr retain];
        _description = [description retain];
        _localFile = localFile;
        _options = [options retain];
    }
    return self;
}

- (void)dealloc {
    [_name release];
    [_urlAddress release];
    [_description release];
    [_options release];
    [super dealloc];
}

@end
