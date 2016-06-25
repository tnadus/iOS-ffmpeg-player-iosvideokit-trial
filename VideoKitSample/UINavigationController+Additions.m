//
//  UINavigationController+Additions.m
//  VideoKit
//
//  Created by Murat Sudan on 03.02.2013.
//  Copyright (c) 2013 VideoKit. All rights reserved.
//

#import "UINavigationController+Additions.h"

@implementation UINavigationController (Additions)

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
