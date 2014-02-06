//
//  ChannelsManager.m
//  VideoKitSample
//
//  Created by Tarum Nadus on 26.10.2013.
//  Copyright (c) 2013 VideoKit. All rights reserved.
//

#import "ChannelsManager.h"
#import "VKPlayerController.h"

@implementation ChannelsManager

#pragma mark Singleton Methods

@synthesize streamList = _streamList;
@synthesize fileList = _fileList;

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
        [self fillChannelList];
    }
    return self;
}

- (void)fillChannelList {
    
    _fileList = [[NSMutableArray array] retain];
    _streamList = [[NSMutableArray array] retain];
    
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
    
    
    Channel *c01 = [Channel channelWithName:@"NTVa" addr:@"http://api.playem.fm/test.mp4a" description:@"mmsh sample stream" localFile:NO options:NULL];
    [_streamList addObject:c01];
    
    Channel *c1 = [Channel channelWithName:@"NTV" addr:@"mmsh://85.111.3.55/ntv" description:@"mmsh sample stream" localFile:NO options:NULL];
    [_streamList addObject:c1];
    
    Channel *c2 = [Channel channelWithName:@"Cartoon TV" addr:@"rtsp://ws2.gpom.com/cartoon" description:@"rtsp sample stream" localFile:NO options:[NSDictionary dictionaryWithObject:VKDECODER_OPT_VALUE_RTSP_TRANSPORT_TCP forKey:VKDECODER_OPT_KEY_RTSP_TRANSPORT]];
    [_streamList addObject:c2];
    
    Channel *c3 = [Channel channelWithName:@"Sky-news" addr:@"rtsp://live1.wm.skynews.servecast.net/skynews_wmlz_live300k" description:@"rtsp sample stream" localFile:NO options:[NSDictionary dictionaryWithObject:VKDECODER_OPT_VALUE_RTSP_TRANSPORT_TCP forKey:VKDECODER_OPT_KEY_RTSP_TRANSPORT]];
    [_streamList addObject:c3];
    
    Channel *c4 = [Channel channelWithName:@"Bloomberg" addr:@"http://strm-i.glb.pr.medianova.tv:1935/bloomberght/smil:bloomberght.smil/chunklist-b128000.m3u8?wowzasessionid=1108965522" description:@"http sample stream" localFile:NO options:NULL];
    [_streamList addObject:c4];
    
    Channel *c5 = [Channel channelWithName:@"RT 1" addr:@"rtmp://fms5.visionip.tv/live/RT_1" description:@"rtmp sample stream" localFile:NO options:NULL];
    [_streamList addObject:c5];
    
    Channel *c6 = [Channel channelWithName:@"Alanya Sahil" addr:@"rtsp://193.164.132.157/kamera3?MSWMExt=.asf" description:@"rtsp sample IP CAM" localFile:NO options:[NSDictionary dictionaryWithObject:VKDECODER_OPT_VALUE_RTSP_TRANSPORT_TCP forKey:VKDECODER_OPT_KEY_RTSP_TRANSPORT]];
    [_streamList addObject:c6];
    
    Channel *c7 = [Channel channelWithName:@"Amalsviken" addr:@"http://194.17.150.25/axis-cgi/mjpg/video.cgi?camera=&resolution=320x240" description:@"mjpeg sample stream" localFile:NO options:[NSDictionary dictionaryWithObject:@"1" forKey:VKDECODER_OPT_KEY_FORCE_MJPEG]];
    [_streamList addObject:c7];
    
    Channel *c8 = [Channel channelWithName:@"Big Buck Bunny" addr:@"http://www.wowza.com/_h264/BigBuckBunny_175k.mov" description:@"http sample mov video file" localFile:NO options:NULL];
    [_streamList addObject:c8];
    
    Channel *c9 = [Channel channelWithName:@"Iron Man II" addr:@"http://santai.tv/vod/test/test_format_1.3gp" description:@"http sample 3gp video file" localFile:NO options:NULL];
    [_streamList addObject:c9];
    
    Channel *c10 = [Channel channelWithName:@"R.T Erdogan" addr:@"http://dl.dropbox.com/u/6355786/tayyip.mp4" description:@"http sample mp4 video file" localFile:NO options:NULL];
    [_streamList addObject:c10];
    
    Channel *c11 = [Channel channelWithName:@"Show radyo" addr:@"mmsh://84.16.235.90/ShowRadyo" description:@"mmsh sample audio stream" localFile:NO options:NULL];
    [_streamList addObject:c11];
    
    Channel *c12 = [Channel channelWithName:@"Radio Javan" addr:@"http://stream.radiojavan.com/radiojavan" description:@"http sample audio stream" localFile:NO options:NULL];
    [_streamList addObject:c12];
    
    Channel *c13 = [Channel channelWithName:@"Power FM" addr:@"http://46.20.4.43:8130/" description:@"http sample aac+ audio stream" localFile:NO options:NULL];
    [_streamList addObject:c13];
    
    Channel *c14 = [Channel channelWithName:@"Aflam Live TV" addr:@"rtmp://95.211.148.203/live/aflam4youddd?id=152675 -rtmp_swfurl http://mips.tv/content/scripts/eplayer.swf -rtmp_live live -rtmp_pageurl http://mips.tv/embedplayer/aflam4youddd/1/600/380 -rtmp_conn S:OK" description:@"Pass through params - ffplay style" localFile:NO options:[NSDictionary dictionaryWithObject:@"1" forKey:VKDECODER_OPT_KEY_PASS_THROUGH]];
    [_streamList addObject:c14];
    
    Channel *c15 = [Channel channelWithName:@"Fake stream" addr:@"http://stream.fake.com" description:@"fake stream to test failure" localFile:NO options:NULL];
    [_streamList addObject:c15];
    
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
    [_streamList release];
    [_fileList release];
    [super dealloc];
}

@end