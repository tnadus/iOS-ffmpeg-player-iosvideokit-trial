//
//  UITabBarController+Additions.m
//  VideoKitSample
//
//  Created by Murat Sudan on 13.10.2013.
//  Copyright (c) 2013 VideoKit. All rights reserved.
//

#import "UITabBarController+Additions.h"

@implementation UITabBarController (Additions)

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
