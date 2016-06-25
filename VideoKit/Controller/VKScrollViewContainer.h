//
//  VKScrollViewContainer.h
//  VideoKitSample
//
//  Created by Murat Sudan on 15/04/16.
//  Copyright © 2016 iosvideokit. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  VKScrollViewContainer is a container that helps VKPlayerController object zoom & scroll anywhere in video frame
 *
 */
@interface VKScrollViewContainer : UIScrollView <UIScrollViewDelegate>

///A view that scrollview is zooming
@property (nonatomic, assign) UIView *zoomView;

///A control property, and When it's set to YES, scrollView sets its some states to fill the given rect. Default is NO
@property (nonatomic, assign) BOOL fillScreen;

///A control property to disable centering zoom view when its value is set to YES.
@property (nonatomic, assign) BOOL disableCenterViewNow;

@end
