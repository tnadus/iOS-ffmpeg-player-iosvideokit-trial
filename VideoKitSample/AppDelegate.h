//
//  AppDelegate.h
//  VideoKit
//
//  Created by Murat Sudan
//  Copyright (c) 2014 iOS VideoKit. All rights reserved.
//  Elma DIGITAL
//

#import <UIKit/UIKit.h>
#import "UINavigationController+Additions.h"

#ifndef RTL
#       define TR(A) NSLocalizedString((A), @"")
#else
#       define TR(A) [NSLocalizedString((A), @"") stringReversed]
#endif

#import "EAIntroView.h"

@class FullScreenSampleViewController;
@class EmbeddedSampleViewController;
@class MultiplePlayersSampleViewController;
@class CustomIOSampleViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate, EAIntroDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *navbarFSSampleVc;
@property (strong, nonatomic) FullScreenSampleViewController *channelListVc;
@property (strong, nonatomic) EmbeddedSampleViewController *subviewDemoVc;
@property (strong, nonatomic) MultiplePlayersSampleViewController *multiPlayersVc;
@property (strong, nonatomic) CustomIOSampleViewController *customIOVc;
@property (strong, nonatomic) UITabBarController *tabBarController;

@end
