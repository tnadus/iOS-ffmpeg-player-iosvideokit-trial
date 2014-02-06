//
//  UITabBarController+Additions.m
//  VideoKitSample
//
//  Created by Tarum Nadus on 13.10.2013.
//  Copyright (c) 2013 VideoKit. All rights reserved.
//

#import "UITabBarController+Additions.h"

@implementation UITabBarController (Additions)

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (BOOL)shouldAutorotate
{
    return YES;
}
#endif

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
