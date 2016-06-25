//
//  ChannelsManager.m
//  VideoKitSample
//
//  Created by Murat Sudan
//  Copyright (c) 2014 iOS VideoKit. All rights reserved.
//  Elma DIGITAL
//

#import "ChannelsManager.h"
#import "VKPlayerController.h"

@implementation ChannelsManager

#pragma mark Singleton Methods

@synthesize streamList = _streamList;
@synthesize fileList = _fileList;
@synthesize recordList = _recordList;

+ (id)sharedManager {
    static ChannelsManager *sharedChannelsManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedChannelsManager = [[self alloc] init];
    });
    return sharedChannelsManager;
}

- (id)init {
    if (self = [super init]) {
        [self updateChannelList];
    }
    return self;
}

- (void)updateChannelList {
    
    if (_fileList) {
        [_fileList removeAllObjects];
        [_fileList release];
        _fileList = NULL;
    }
    
    if (_streamList) {
        [_streamList removeAllObjects];
        [_streamList release];
        _streamList = NULL;
    }

#ifdef VK_RECORDING_CAPABILITY
    if (_recordList) {
        [_recordList removeAllObjects];
        [_recordList release];
        _recordList = NULL;
    }
#endif
    
    _fileList = [[NSMutableArray array] retain];
    _streamList = [[NSMutableArray array] retain];
#ifdef VK_RECORDING_CAPABILITY
    _recordList = [[NSMutableArray array] retain];
#endif
    
    //adding media files
    Channel *cl1 = [Channel channelWithName:@"despicable" addr:[[NSBundle mainBundle] pathForResource:@"despicable" ofType:@"mp4"] description:@"local file sample in bundle" localFile:NO options:NULL];
    [_fileList addObject:cl1];
    
    Channel *cl2 = [Channel channelWithName:@"iphone5c" addr:[[NSBundle mainBundle] pathForResource:@"iphone5c" ofType:@"mp4"] description:@"local file sample in bundle" localFile:NO options:NULL];
    [_fileList addObject:cl2];
    
    Channel *cl3 = [Channel channelWithName:@"kitkat" addr:[[NSBundle mainBundle] pathForResource:@"kitkat" ofType:@"flv"] description:@"local file sample in bundle" localFile:NO options:NULL];
    [_fileList addObject:cl3];
        
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];
    for (NSString *item in array) {
        Channel *c = [Channel channelWithName:item addr:[NSString stringWithFormat:@"%@/%@",documentsDirectory,item] description:@"local file sample in doc" localFile:YES options:NULL];
        [_fileList addObject:c];
    }

    //adding remote streams

    Channel *chanMPL = [Channel channelWithName:@"MPL TV" addr:@"rtsp://mpl.dyndns.tv/MPL" description:@"rtsp sample stream" localFile:NO options:[NSDictionary dictionaryWithObject:VKDECODER_OPT_VALUE_RTSP_TRANSPORT_TCP forKey:VKDECODER_OPT_KEY_RTSP_TRANSPORT]];
    [_streamList addObject:chanMPL];

    Channel *chanBigBuckBunny = [Channel channelWithName:@"Big Buck Bunny" addr:@"rtsp://wowzaec2demo.streamlock.net/vod/mp4:BigBuckBunny_115k.mov" description:@"rtsp sample stream" localFile:NO options:[NSDictionary dictionaryWithObject:VKDECODER_OPT_VALUE_RTSP_TRANSPORT_TCP forKey:VKDECODER_OPT_KEY_RTSP_TRANSPORT]];
    [_streamList addObject:chanBigBuckBunny];

    Channel *chanEURONEWS = [Channel channelWithName:@"EURONEWS" addr:@"rtsp://ewns-hls-b-stream.hexaglobe.net/rtpeuronewslive/tr_vidan750_rtp.sdp" description:@"rtsp sample stream" localFile:NO options:[NSDictionary dictionaryWithObject:VKDECODER_OPT_VALUE_RTSP_TRANSPORT_TCP forKey:VKDECODER_OPT_KEY_RTSP_TRANSPORT]];
    [_streamList addObject:chanEURONEWS];

    Channel *chanBloom = [Channel channelWithName:@"Bloomberg" addr:@"http://mn-l.mncdn.com/bloomberght/bloomberght2/radyodelisi.m3u8" description:@"http sample stream" localFile:NO options:NULL];
    [_streamList addObject:chanBloom];

    Channel *chanKids = [Channel channelWithName:@"Kids Cena Wiffle" addr:@"rtmp://flvideo.wwe.com/wwevideo/flv/kids/2008/october8-14/kids_cena_wiffle_large.flv" description:@"rtmp sample stream" localFile:NO options:NULL];
    [_streamList addObject:chanKids];

    Channel *chanBeotel = [Channel channelWithName:@"Beotel Studio B" addr:@"mms://beotelmedia.beotel.net/studiob" description:@"mms sample stream" localFile:NO options:NULL];
    [_streamList addObject:chanBeotel];

    Channel *chanKjollefjordWebcam = [Channel channelWithName:@"Kjøllefjord webcam" addr:@"http://81.93.105.4/axis-cgi/mjpg/video.cgi?camera=1&resolution=704x576" description:@"mjpeg sample stream" localFile:NO options:[NSDictionary dictionaryWithObject:@"1" forKey:VKDECODER_OPT_KEY_FORCE_MJPEG]];
    [_streamList addObject:chanKjollefjordWebcam];

    Channel *chanRaiYoyo = [Channel channelWithName:@"Rai Yoyo" addr:@"mmsh://212.162.68.162/rai_yoyo" description:@"mmsh sample stream" localFile:NO options:NULL];
    [_streamList addObject:chanRaiYoyo];

    Channel *chanJavan = [Channel channelWithName:@"Radio Javan" addr:@"http://stream.radiojavan.com/radiojavan" description:@"http sample audio stream" localFile:NO options:NULL];
    [_streamList addObject:chanJavan];

    Channel *chanPower = [Channel channelWithName:@"Power FM" addr:@"http://icast.powergroup.com.tr:80/PowerGymTonic/mpeg/128/home" description:@"http sample mp3 audio stream" localFile:NO options:NULL];
    [_streamList addObject:chanPower];
    
    Channel *chanKitkat = [Channel channelWithName:@"Kitkat on dropbox" addr:@"https://dl.dropboxusercontent.com/u/6355786/kitkat.flv" description:@"https sample stream" localFile:NO options:NULL];
    [_streamList addObject:chanKitkat];
    
    Channel *chanFake = [Channel channelWithName:@"Fake stream" addr:@"http://stream.fake.com" description:@"fake stream to test failure" localFile:NO options:NULL];
    [_streamList addObject:chanFake];
  
#ifdef VK_RECORDING_CAPABILITY
    //adding record files
    NSString *tmpDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"tmp"];
    NSArray *records = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:tmpDirectory error:nil];
    for (NSString *item in records) {
        Channel *c = [Channel channelWithName:item addr:[NSString stringWithFormat:@"%@/%@",tmpDirectory,item] description:@"recorded file sample in tmp" localFile:YES options:NULL];
        [_recordList addObject:c];
    }
#endif
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
#ifdef VK_RECORDING_CAPABILITY
    [_recordList release];
#endif
    [_streamList release];
    [_fileList release];
    [super dealloc];
}

@end