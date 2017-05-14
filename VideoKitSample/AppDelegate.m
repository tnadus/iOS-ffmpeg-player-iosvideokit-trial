//
//  AppDelegate.m
//  VideoKit
//
//  Created by Murat Sudan
//  Copyright (c) 2014 iOS VideoKit. All rights reserved.
//  Elma DIGITAL
//

#import "AppDelegate.h"
#import "FullScreenSampleViewController.h"
#import "EmbeddedSampleViewController.h"
#import "MultiplePlayersSampleViewController.h"
#import "CustomIOSampleViewController.h"

#define WRITE_LOGS_TO_FILE         0

@implementation AppDelegate

@synthesize navbarFSSampleVc = _navbarFSSampleVc;
@synthesize channelListVc = _channelListVc;
@synthesize tabBarController = _tabBarController;
@synthesize subviewDemoVc = _subviewDemoVc;
@synthesize multiPlayersVc = _multiPlayersVc;
@synthesize customIOVc = _customIOVc;

- (void)dealloc
{
    [_customIOVc release];
    [_subviewDemoVc release];
    [_multiPlayersVc release];
    [_channelListVc release];
    [_navbarFSSampleVc release];
    [_tabBarController release];
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

#if (TARGET_IPHONE_SIMULATOR == 0) && (WRITE_LOGS_TO_FILE)
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *logPath = [documentsDirectory stringByAppendingPathComponent:@"console.log"];
    freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
#endif

    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor blackColor];
    self.tabBarController = [[[UITabBarController alloc] init] autorelease];
    self.tabBarController.tabBar.tintColor = [UIColor darkGrayColor];

    self.channelListVc = [[[FullScreenSampleViewController alloc] initWithNibName:@"FullScreenSampleViewController" bundle:nil] autorelease];
    self.navbarFSSampleVc = [[[UINavigationController alloc] initWithRootViewController:_channelListVc] autorelease];

    self.subviewDemoVc = [[[EmbeddedSampleViewController alloc] initWithNibName:@"EmbeddedSampleViewController" bundle:nil] autorelease];
    self.multiPlayersVc = [[[MultiplePlayersSampleViewController alloc] initWithNibName:@"MultiplePlayersSampleViewController" bundle:nil] autorelease];
    self.customIOVc = [[[CustomIOSampleViewController alloc] initWithNibName:@"CustomIOSampleViewController" bundle:nil] autorelease];

    self.tabBarController.viewControllers = [NSArray arrayWithObjects:_navbarFSSampleVc, _subviewDemoVc, _multiPlayersVc, _customIOVc, nil];
    self.window.rootViewController = self.tabBarController;
    [self addIntroView:NO];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)addIntroView:(BOOL)forceToShow {
    
    if (!forceToShow && [[[NSUserDefaults standardUserDefaults] objectForKey:@"dont_show_again"] boolValue])
        return;
    
    EAIntroPage *page1 = [EAIntroPage page];
    page1.title = @"Welcome to VideoKit Sample";
    page1.desc = @"This sample project includes full screen and embedded representation of video player. Also, multi players tab is a bonus.";
    page1.titleImage = [UIImage imageNamed:@"intro-screen-1"];
    
    EAIntroPage *page2 = [EAIntroPage page];
    page2.title = @"How to test your streams/media files";
    page2.desc = @"ChannelManager is the place for adding/removing/editing the channels. You can add network streams and local media files. Media files that added to Application Documents folder via file sharing are automatically created as a channel in channel list.";
    page2.titleImage = [UIImage imageNamed:@"intro-screen-2"];
    
    EAIntroPage *page3 = [EAIntroPage page];
    page3.title = @"Gestures";
    page3.desc = @"In this sample, You can use gestures on player, tap for displaying player user interface, pinch in/out - double tap for zoom in/out, and long press for transitining between fullscreen & embed window states.";
    page3.titleImage = [UIImage imageNamed:@"intro-screen-3"];
    
    EAIntroPage *page4 = [EAIntroPage page];
    page4.title = @"Custom IO";
    page4.desc = @"It's possible to provide your custom audio/video stream data to VideoKit, no need to provide a file or network url. Just give your data in memory! (please see CustomIOSampleViewController.m for more info.)";
    page4.titleImage = [UIImage imageNamed:@"intro-screen-5"];
    
    EAIntroPage *page5 = [EAIntroPage page];
    page5.title = @"Questions";
    page5.desc = @"You can find the documentation in documentation folder, for further support you can e-mail : support@iosvideokit.com";
    page5.titleImage = [UIImage imageNamed:@"intro-screen-4"];
    
    EAIntroView *intro = [[EAIntroView alloc] initWithFrame:self.window.bounds andPages:@[page1,page2,page3,page4,page5]];
    intro.bgImage = [UIImage imageNamed:@"introBg"];
    [intro setDelegate:self];
    [intro showInView:self.tabBarController.view animateDuration:0.0];
}

#pragma mark - UIApplication life cycle callbacks

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
