//
//  VKFullscreenContainer.m
//  VideoKitSample
//
//  Created by Murat Sudan on 14/04/16.
//  Copyright © 2016 iosvideokit. All rights reserved.
//

#import "VKFullscreenContainer.h"
#import "VKPlayerControllerBase.h"
#import "VKGLES2View.h"

#pragma mark - VKFullscreenContainer

@implementation VKFullscreenContainer

- (id)initWithPlayerController:(VKPlayerControllerBase *)player windowRect:(CGRect)rect {
    self = [super init];
    if (self) {
        _playerController = [player retain];
        _rectBefore = [player.view frame];
        _rectWin = rect;
        _superviewBefore = [[player.view superview] retain];
        _autoresizingMaskBefore = [player.view autoresizingMask];
    }
    return self;
}

#pragma mark - View Life Cycle

- (void) loadView {
    self.view = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

#pragma mark - Private Methods

- (BOOL)prefersStatusBarHidden {
    return [_playerController isStatusBarHidden];
}

- (void)dismissContainerWithAnimated:(BOOL)animated completionHandler:(void (^)(void))completionHandler {
    float duration = (animated) ? .5 : 0.0;
    
    UIWindow *keyWindow = [[[UIApplication sharedApplication] windows] lastObject];
    
#if !TARGET_OS_TV
        //first animation - start coloring clearcolor
        
        [(VKScrollViewContainer *)[_playerController scrollView] setDisableCenterViewNow:YES];
        
        __block NSLayoutConstraint *constraintTopByWin = nil, *constraintLeftByWin = nil, *constraintWidthByWin = nil, *constraintHeightByWin = nil;
        
        [UIView animateWithDuration:0.2 animations:^{
            self.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
            _playerController.scrollView.backgroundColor = [UIColor clearColor];
        } completion:^(BOOL finished) {
            [keyWindow addSubview:_playerController.view];
            
            if (![_playerController.view translatesAutoresizingMaskIntoConstraints]) {
                //Set Autolayout constraints self.view
                
                for (NSLayoutConstraint *constaint in keyWindow.constraints) {
                    if (constaint.firstItem == _playerController.view) {
                        if (constaint.firstAttribute == NSLayoutAttributeTop) {
                            constraintTopByWin = constaint;
                        } else if (constaint.firstAttribute == NSLayoutAttributeLeft) {
                            constraintLeftByWin = constaint;
                        } else if (constaint.firstAttribute == NSLayoutAttributeWidth) {
                            constraintWidthByWin = constaint;
                        } else if (constaint.firstAttribute == NSLayoutAttributeHeight) {
                            constraintHeightByWin = constaint;
                        }
                    }
                }
                
                if (!constraintTopByWin) {
                    // align self.view from the top
                    constraintTopByWin = [NSLayoutConstraint constraintWithItem:_playerController.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:keyWindow attribute:NSLayoutAttributeTop multiplier:1.0 constant:keyWindow.frame.origin.y];
                    [keyWindow addConstraint:constraintTopByWin];
                }
                
                if (!constraintLeftByWin) {
                    // align self.view from the left
                    constraintLeftByWin = [NSLayoutConstraint constraintWithItem:_playerController.view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:keyWindow attribute:NSLayoutAttributeLeft multiplier:1.0 constant:keyWindow.frame.origin.x];
                    [keyWindow addConstraint:constraintLeftByWin];
                }
                
                if (!constraintWidthByWin) {
                    // self.view width constant
                    constraintWidthByWin = [NSLayoutConstraint constraintWithItem:_playerController.view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:NULL attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:keyWindow.frame.size.width];
                    [keyWindow addConstraint:constraintWidthByWin];
                }
                
                if (!constraintHeightByWin) {
                    // self.view height constant
                    constraintHeightByWin = [NSLayoutConstraint constraintWithItem:_playerController.view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:NULL attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:keyWindow.frame.size.height];
                    [keyWindow addConstraint:constraintHeightByWin];
                }
            }
            
            [self dismissViewControllerAnimated:NO completion:^{
                [UIView animateWithDuration:duration animations:^{
                    if (![_playerController.view translatesAutoresizingMaskIntoConstraints]) {
                        constraintTopByWin.constant = _rectBefore.origin.y;
                        constraintLeftByWin.constant = _rectBefore.origin.x;
                        constraintWidthByWin.constant = _rectBefore.size.width;
                        constraintHeightByWin.constant = _rectBefore.size.height;
                        [keyWindow setNeedsLayout];
                        [keyWindow layoutIfNeeded];
                    } else {
                        _playerController.view.frame = _rectBefore;
                    }
                    
                    if ([_playerController mainScreenIsMobile]) {
                        _playerController.renderView.frame = [_playerController.renderView exactFrameRectForSize:_playerController.view.bounds.size fillScreen:[_playerController fillScreen]];
                    }
                    _playerController.view.backgroundColor = [UIColor clearColor];
                    _playerController.scrollView.backgroundColor = _playerController.view.backgroundColor;
                } completion:^(BOOL finished) {
                    
                    [_superviewBefore addSubview:_playerController.view];
                    
                    if (![_playerController.view translatesAutoresizingMaskIntoConstraints]) {
                        NSDictionary *metricsSuperView = @{@"playerview_left": @(_rectBefore.origin.x), @"playerview_top": @(_rectBefore.origin.y),
                                                           @"playerview_width": @(_rectBefore.size.width), @"playerview_height": @(_rectBefore.size.height)};
                        UIView *playerView = _playerController.view;
                        // align playerView from the left
                        [_superviewBefore addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-playerview_left-[playerView(==playerview_width)]" options:0 metrics:metricsSuperView views:NSDictionaryOfVariableBindings(playerView)]];
                        // align playerView from the top
                        [_superviewBefore addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-playerview_top-[playerView(==playerview_height)]" options:0 metrics:metricsSuperView views:NSDictionaryOfVariableBindings(playerView)]];
                    } else {
                        _playerController.view.autoresizingMask = _autoresizingMaskBefore;
                    }
                    
                    if ([_playerController mainScreenIsMobile]) {
                        [(VKScrollViewContainer *)[_playerController scrollView] setDisableCenterViewNow:NO];
                    }
                    
                    [_playerController.scrollView setNeedsLayout];
                    [_playerController.scrollView layoutIfNeeded];
                    [_playerController.renderView updateOpenGLFrameSizes];
                    
                    [UIView animateWithDuration:0.1 animations:^{
                        _playerController.view.backgroundColor = [UIColor blackColor];
                        _playerController.scrollView.backgroundColor = _playerController.view.backgroundColor;
                    }];
                    
                }];
            }];
        }];
#else
//os is tvOS (AppleTV)
        
        [(VKScrollViewContainer *)[_playerController scrollView] setDisableCenterViewNow:YES];
        [keyWindow addSubview:_playerController.view];
        
        __block NSLayoutConstraint *constraintTopByWin = nil, *constraintLeftByWin = nil, *constraintWidthByWin = nil, *constraintHeightByWin = nil;
        
        if (![_playerController.view translatesAutoresizingMaskIntoConstraints]) {
            //Set Autolayout constraints self.view
            
            for (NSLayoutConstraint *constaint in keyWindow.constraints) {
                if (constaint.firstItem == _playerController.view) {
                    if (constaint.firstAttribute == NSLayoutAttributeTop) {
                        constraintTopByWin = constaint;
                    } else if (constaint.firstAttribute == NSLayoutAttributeLeft) {
                        constraintLeftByWin = constaint;
                    } else if (constaint.firstAttribute == NSLayoutAttributeWidth) {
                        constraintWidthByWin = constaint;
                    } else if (constaint.firstAttribute == NSLayoutAttributeHeight) {
                        constraintHeightByWin = constaint;
                    }
                }
            }
            
            if (!constraintTopByWin) {
                // align self.view from the top
                constraintTopByWin = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:keyWindow attribute:NSLayoutAttributeTop multiplier:1.0 constant:keyWindow.frame.origin.y];
                [keyWindow addConstraint:constraintTopByWin];
            }
            
            if (!constraintLeftByWin) {
                // align self.view from the left
                constraintLeftByWin = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:keyWindow attribute:NSLayoutAttributeLeft multiplier:1.0 constant:keyWindow.frame.origin.x];
                [keyWindow addConstraint:constraintLeftByWin];
            }
            
            if (!constraintWidthByWin) {
                // self.view width constant
                constraintWidthByWin = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:NULL attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:keyWindow.frame.size.width];
                [keyWindow addConstraint:constraintWidthByWin];
            }
            
            if (!constraintHeightByWin) {
                // self.view height constant
                constraintHeightByWin = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:NULL attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:keyWindow.frame.size.height];
                [keyWindow addConstraint:constraintHeightByWin];
            }
            
        } else {
            _playerController.view.frame = keyWindow.bounds;
        }
        
        [self dismissViewControllerAnimated:NO completion:^{
            
            constraintTopByWin.constant = _rectWin.origin.y;
            constraintLeftByWin.constant = _rectWin.origin.x;
            constraintWidthByWin.constant = _rectWin.size.width;
            constraintHeightByWin.constant = _rectWin.size.height;
            
            [UIView animateWithDuration:duration animations:^{
                if (![_playerController.view translatesAutoresizingMaskIntoConstraints]) {
                    [keyWindow setNeedsLayout];
                    [keyWindow layoutIfNeeded];
                } else {
                    _playerController.view.frame = _rectWin;
                }
                _playerController.renderView.frame = [_playerController.renderView exactFrameRectForSize:_playerController.view.bounds.size fillScreen:[_playerController fillScreen]];
                
            } completion:^(BOOL finished) {
                [_superviewBefore addSubview:_playerController.view];
                
                if (![_playerController.view translatesAutoresizingMaskIntoConstraints]) {
                    NSDictionary *metricsSuperView = @{@"playerview_left": @(_rectBefore.origin.x), @"playerview_top": @(_rectBefore.origin.y),
                                                       @"playerview_width": @(_rectBefore.size.width), @"playerview_height": @(_rectBefore.size.height)};
                    UIView *playerView = _playerController.view;
                    // align playerView from the left
                    [_superviewBefore addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-playerview_left-[playerView(==playerview_width)]" options:0 metrics:metricsSuperView views:NSDictionaryOfVariableBindings(playerView)]];
                    // align playerView from the top
                    [_superviewBefore addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-playerview_top-[playerView(==playerview_height)]" options:0 metrics:metricsSuperView views:NSDictionaryOfVariableBindings(playerView)]];
                } else {
                    _playerController.view.frame = _rectBefore;
                    _playerController.view.autoresizingMask = _autoresizingMaskBefore;
                }
                
                [(VKScrollViewContainer *)[_playerController scrollView] setDisableCenterViewNow:NO];
                
                [_playerController.scrollView setNeedsLayout];
                [_playerController.scrollView layoutIfNeeded];
                [_playerController.renderView updateOpenGLFrameSizes];
                
                if (completionHandler) {
                    completionHandler();
                }
            }];
        }];
#endif
    
}

#pragma mark - Orientation

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Toolbar position delegate

- (UIBarPosition)positionForBar:(id <UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}

- (void)dealloc {
    [_superviewBefore release];
    [_playerController release];
    [super dealloc];
}

@end
