//
//  AppDelegate.h
//  VideoKit
//
//  Created by Tarum Nadus on 11/16/12.
//  Copyright (c) 2013-2014 VideoKit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UINavigationController+Additions.h"
#import "EAIntroView.h"

@class FullScreenSampleViewController;
@class EmbeddedSampleViewController;
@class MultiplePlayersSampleViewController;
@class OtherViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate, EAIntroDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *navbarFSSampleVc;
@property (strong, nonatomic) UINavigationController *navbarOtherVc;
@property (strong, nonatomic) FullScreenSampleViewController *channelListVc;
@property (strong, nonatomic) EmbeddedSampleViewController *subviewDemoVc;
@property (strong, nonatomic) MultiplePlayersSampleViewController *multiPlayersVc;
@property (strong, nonatomic) OtherViewController *otherVc;
@property (strong, nonatomic) UITabBarController *tabBarController;

@end
