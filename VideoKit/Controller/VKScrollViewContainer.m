//
//  VKScrollViewContainer.m
//  VideoKitSample
//
//  Created by Murat Sudan on 15/04/16.
//  Copyright © 2016 iosvideokit. All rights reserved.
//

#import "VKScrollViewContainer.h"
#import "VKGLES2View.h"
#import "VKDecodeManager.h"

#define kVKPlayerContainerScrollViewZoomLevelMin               1.0
#define kVKPlayerContainerScrollViewZoomLevelMax               3.0

@interface VKScrollViewContainer () {
    
    //Control properties
    BOOL _isAutoZooming;
    BOOL _isDraggingNow;
    BOOL _disableCenterViewNow;
    BOOL _fillScreen;
    BOOL _rotPortrait;
}

@end

@implementation VKScrollViewContainer

@synthesize zoomView = _zoomView;
@synthesize disableCenterViewNow = _disableCenterViewNow;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.bouncesZoom = NO;
        self.bounces = NO;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.minimumZoomScale = kVKPlayerContainerScrollViewZoomLevelMin;
        self.maximumZoomScale = kVKPlayerContainerScrollViewZoomLevelMax;
        self.zoomScale = self.minimumZoomScale;
        self.delegate = self;
        
#if TARGET_OS_IOS
        _rotPortrait = (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) ? YES : NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRotation:) name:UIDeviceOrientationDidChangeNotification object:nil];
#endif
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    VKLog(kVKLogLevelUIControlExtra, @"VKScrollViewContainer->layoutSubviews");
    
    if (!_isAutoZooming && !_disableCenterViewNow)
        [self centerScrollViewContents];
}

- (void)centerScrollViewContents {
    VKLog(kVKLogLevelUIControlExtra, @"VKScrollViewContainer->centerScrollViewContents");
    VKLog(kVKLogLevelUIControlExtra, @"VKScrollViewContainer->scrollview.contentOffset: (%f, %f)", self.contentOffset.x, self.contentOffset.y);
    
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = _zoomView.frame;
    
    float zoomLevel = [self zoomScale];
    BOOL resetFrame = NO;
        
    if (zoomLevel != 1.0 && (frameToCenter.size.width == boundsSize.height)) {
        resetFrame = YES;
    }
    
    if (!_isDraggingNow && (zoomLevel == 1.0 || resetFrame)) {
        [self resetZoomViewFrame:boundsSize];
    } else {
        // center horizontally
        if (frameToCenter.size.width < boundsSize.width)
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
        else
            frameToCenter.origin.x = 0;
        
        // center vertically
        if (frameToCenter.size.height < boundsSize.height)
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
        else
            frameToCenter.origin.y = 0;
        
        _zoomView.frame = frameToCenter;
    }
    VKLog(kVKLogLevelUIControlExtra, @"VKScrollViewContainer->scrollview.contentOffset: (%f, %f)", self.contentOffset.x, self.contentOffset.y);
}

- (void)resetZoomViewFrame:(CGSize)boundsSize {
    VKLog(kVKLogLevelUIControlExtra, @"VKScrollViewContainer->resetZoomViewFrame");
    CGRect r = [(VKGLES2View *)_zoomView exactFrameRectForSize:boundsSize fillScreen:_fillScreen];
    _zoomView.frame = CGRectMake(0.0, r.origin.y, r.size.width, r.size.height);
    self.contentSize = CGSizeMake(r.size.width, r.size.height);
    self.contentOffset = CGPointMake(-r.origin.x, 0.0);
    self.zoomScale = 1.0;
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _zoomView;
}

- (void)zoomToRect:(CGRect)rect animated:(BOOL)animated
{
    [UIView animateWithDuration:(animated?0.3f:0.0f)
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         _isAutoZooming = YES;
                         [super zoomToRect:rect animated:NO];
                     }
                     completion:^(BOOL finished) {
                         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                             _isAutoZooming = NO;
                         });
                     }];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    VKLog(kVKLogLevelUIControlExtra, @"VKScrollViewContainer->scrollViewDidZoom atScale:%f", self.zoomScale);
    [self centerScrollViewContents];
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view {
    VKLog(kVKLogLevelUIControlExtra, @"VKScrollViewContainer->scrollViewWillBeginZooming atScale:%f", self.zoomScale);
    if (_zoomView) {
        [(VKGLES2View *)_zoomView setStopUpdateGLSize:YES];
    }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view atScale:(CGFloat)scale {
    VKLog(kVKLogLevelUIControlExtra, @"VKScrollViewContainer->scrollview.scrollViewDidEndZooming atScale:%f", scale);
    if (_zoomView) {
        [(VKGLES2View *)_zoomView setStopUpdateGLSize:NO];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    VKLog(kVKLogLevelUIControlExtra, @"VKScrollViewContainer->scrollview.scrollViewWillBeginDragging");
    _isDraggingNow = YES;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    VKLog(kVKLogLevelUIControlExtra, @"VKScrollViewContainer->scrollview.scrollViewWillEndDragging");
    _isDraggingNow = NO;
}

#pragma mark - Rotation

- (void)onRotation:(NSNotification *)theNotification {
    VKLog(kVKLogLevelUIControlExtra, @"VKScrollView->onRotation");
#if TARGET_OS_IOS
    BOOL rotCurrPortrait = (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) ? YES : NO;
    if (_rotPortrait != rotCurrPortrait) {
        _rotPortrait = rotCurrPortrait;
        [self resetZoomViewFrame:self.bounds.size];
    }
#endif
}

#pragma mark - Memory deallocation

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

@end
