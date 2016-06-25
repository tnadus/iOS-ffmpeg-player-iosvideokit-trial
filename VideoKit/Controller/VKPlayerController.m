//
//  VKPlayerViewController.m
//  VideoKit
//
//  Created by Murat Sudan
//  Copyright (c) 2014 iOS VideoKit. All rights reserved.
//  Elma DIGITAL
//

#if __has_feature(objc_arc)
#error iOS VideoKit is Non-ARC only. Either turn off ARC for the project or use -fobjc-no-arc flag on source files (Targets -> Build Phases -> Compile Sources)
#endif

#import "VKPlayerController.h"
#import "VKGLES2View.h"
#import "VKStreamInfoView.h"
#import "VKFullscreenContainer.h"

#import <MediaPlayer/MediaPlayer.h>

#pragma mark - VKPlayerController

#define BAR_BUTTON_TAG_DONE             1000
#define BAR_BUTTON_TAG_SCALE            1001

#define PANEL_BUTTON_TAG_PP_TOGGLE      2001
#define PANEL_BUTTON_TAG_INFO           2002
#define PANEL_BUTTON_TAG_FULLSCREEN     2003

#ifdef VK_RECORDING_CAPABILITY
#define PANEL_BUTTON_TAG_RECORD         2004
#endif



@interface VKPlayerController ()<AVAudioSessionDelegate> {


    MPVolumeView *_sliderVolume;
    //UI elements & controls for fullscreen
    UIActivityIndicatorView *_activityIndicator;
    UILabel *_labelBarTitle;
    UIToolbar *_toolBar;
    UIView *_viewCenteredOnBar;

    UIView *_viewControlPanel;
    UIImageView *_imgViewControlPanel;
    UILabel *_labelElapsedTime;
    UIButton *_buttonPanelPP;
    UIButton *_buttonPanelInfo;
#ifdef VK_RECORDING_CAPABILITY
    UIButton *_buttonPanelRecord;
#endif
    UIImageView *_imgViewSpeaker;

    UILabel *_labelStreamCurrentTime;
    UILabel *_labelStreamTotalDuration;
    UISlider *_sliderCurrentDuration;
    
    //UI elements & controls for embedded view
    UIActivityIndicatorView *_activityIndicatorEmbedded;
    UIView *_viewBarEmbedded;
    UILabel *_labelBarEmbedded;
    UILabel *_labelElapsedTimeEmbedded;

    UIView *_viewControlPanelEmbedded;
    UIButton *_buttonPanelPPEmbedded;
    UILabel *_labelStreamCurrentTimeEmbedded;
    UILabel *_labelStreamTotalDurationEmbedded;
    UISlider *_sliderCurrentDurationEmbedded;
    UIButton *_buttonFullScreenEmbedded;

    UILabel *_labelStatusEmbedded;

    //UI elements other
    UIImage *_imgSliderMin;
    UIImage *_imgSliderMax;
    UIImage *_imgSliderThumb;
    
    UIImageView *_imgViewExternalScreen;
    
    //Gestures
    UITapGestureRecognizer *_closeInfoViewGestureRecognizer;
    UILongPressGestureRecognizer *_longGestureRecognizer;

    //Status bar properties
    BOOL _statusBarHiddenBefore;
}

@property (nonatomic, retain) UIWindow *extWindow;
@property (nonatomic, retain) UIScreen *extScreen;

- (IBAction)onBarButtonsTapped:(id)sender;
- (IBAction)onControlPanelButtonsTapped:(id)sender;

@end

@implementation VKPlayerController

@synthesize controlStyle = _controlStyle;

#pragma mark Initialization

- (id)init {
    self = [super initBase];
    if (self) {
        [self prepare];
        return self;
    }
    return nil;
}

- (id)initWithURLString:(NSString *)urlString {
    self = [super initWithURLString:urlString];
    if (self) {
        [self prepare];
    }
    return self;
}

- (void)prepare {
    // Custom initialization
    _panelIsHidden = NO;
    _statusBarHidden = NO;
    _statusBarHiddenBefore = NO;
    _controlStyle = kVKPlayerControlStyleEmbedded;
    [self createUI];
}

#pragma mark Subviews management

- (void)createUI
{
    _view = [[UIView alloc] initWithFrame:CGRectZero];
    self.view.backgroundColor = _backgroundColor;
    
    _imgSliderMin = [[[UIImage imageNamed:@"VKImages.bundle/vk-track-unfilled.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 5, 5)] retain];
    _imgSliderMax = [[[UIImage imageNamed:@"VKImages.bundle/vk-track-filled.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 5, 5)] retain];
    _imgSliderThumb = [[UIImage imageNamed:@"VKImages.bundle/vk-track-knob.png"] retain];
    
    [self createUIFullScreen];
    [self createUIEmbedded];
    [self createUICenter];
    [self addUIEmbedded];
    [self setPanelButtonsEnabled:NO];
}

- (void)createUIFullScreen {
    [self createUIFullScreenBar];
    [self createUIFullScreenPanel];
}

- (void)createUIFullScreenBar {
    /* Toolbar on top: _toolBar */
    _toolBar = [[UIToolbar alloc] initWithFrame:CGRectZero];
    _toolBar.translatesAutoresizingMaskIntoConstraints = NO;
    _toolBar.barStyle = UIBarStyleDefault;
    _toolBar.tintColor = [UIColor darkGrayColor];
    
    NSMutableArray *toolBarItems = [NSMutableArray array];
    
    UIButton *buttonDone = [[[UIButton alloc] init] autorelease];
    buttonDone.translatesAutoresizingMaskIntoConstraints = NO;
    [buttonDone setTitle:TR(@"Done") forState:UIControlStateNormal];
    [[buttonDone titleLabel] setFont:[UIFont boldSystemFontOfSize:16.0]];
    [buttonDone setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [buttonDone setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [buttonDone addTarget:self action:@selector(onBarButtonsTapped:) forControlEvents:UIControlEventTouchUpInside];
    [buttonDone setTag:BAR_BUTTON_TAG_DONE];
    UIBarButtonItem *_barButtonDone = [[[UIBarButtonItem alloc] initWithCustomView:buttonDone] autorelease];
    
    [toolBarItems addObject:_barButtonDone];
    
    /* Toolbar on top: _barButtonSpaceLeft */
    UIBarButtonItem *_barButtonSpaceLeft = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
    [toolBarItems addObject:_barButtonSpaceLeft];
    
    /* Toolbar on top: _viewCenteredOnBar */
    _viewCenteredOnBar = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
    _viewCenteredOnBar.translatesAutoresizingMaskIntoConstraints = NO;
    _viewCenteredOnBar.backgroundColor = [UIColor clearColor];
    
    float heightSubviewOnBar = 21.0;
    float wStrmTimeLabelsOnBar = 40.0;
    
    /* Toolbar on top: _labelBarTitle */
    _labelBarTitle = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    _labelBarTitle.translatesAutoresizingMaskIntoConstraints = NO;
    _labelBarTitle.lineBreakMode = NSLineBreakByTruncatingTail;
    _labelBarTitle.minimumScaleFactor = 0.3;
    _labelBarTitle.textAlignment = NSTextAlignmentCenter;
    _labelBarTitle.contentMode = UIViewContentModeLeft;
    _labelBarTitle.numberOfLines = 1;
    _labelBarTitle.backgroundColor = [UIColor clearColor];
    _labelBarTitle.shadowOffset = CGSizeMake(0.0, -1.0);
    _labelBarTitle.textColor = [UIColor darkGrayColor];
    _labelBarTitle.font = [UIFont fontWithName:@"HelveticaNeue" size:18];
    _labelBarTitle.text = [self staturBarInitialText];
    [_viewCenteredOnBar addSubview:_labelBarTitle];
    
    /* Toolbar on top: _activityIndicator */
    _activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
    _activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    _activityIndicator.hidesWhenStopped = YES;
    _activityIndicator.backgroundColor = [UIColor clearColor];
    [_viewCenteredOnBar addSubview:_activityIndicator];
    
    /* Current & total duration of stream labels */
    float marginX = 8.0;
    _labelStreamCurrentTime = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    _labelStreamCurrentTime.translatesAutoresizingMaskIntoConstraints = NO;
    _labelStreamCurrentTime.textAlignment = NSTextAlignmentCenter;
    _labelStreamCurrentTime.text = @"00:00";
    _labelStreamCurrentTime.numberOfLines = 1;
    _labelStreamCurrentTime.opaque = NO;
    _labelStreamCurrentTime.backgroundColor = [UIColor clearColor];
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending) {
        //running on iOS 7.0 or higher
        _labelStreamCurrentTime.textColor = [UIColor darkGrayColor];
    } else {
        _labelStreamCurrentTime.textColor = [UIColor whiteColor];
    }
    _labelStreamCurrentTime.font = [UIFont fontWithName:@"HelveticaNeue" size:13.0];
    _labelStreamCurrentTime.hidden = YES;
    [_viewCenteredOnBar addSubview:_labelStreamCurrentTime];
    
    /* labelStreamTotalDuration */
    _labelStreamTotalDuration = [[[UILabel alloc] initWithFrame:CGRectMake(_viewCenteredOnBar.frame.size.width - wStrmTimeLabelsOnBar - marginX, 6.0, wStrmTimeLabelsOnBar, heightSubviewOnBar)] autorelease];
    _labelStreamTotalDuration.translatesAutoresizingMaskIntoConstraints = NO;
    _labelStreamTotalDuration.textAlignment = NSTextAlignmentCenter;
    _labelStreamTotalDuration.numberOfLines = 1;
    _labelStreamTotalDuration.opaque = NO;
    _labelStreamTotalDuration.backgroundColor = [UIColor clearColor];
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending) {
        //running on iOS 7.0 or higher
        _labelStreamTotalDuration.textColor = [UIColor darkGrayColor];
    } else {
        _labelStreamTotalDuration.textColor = [UIColor whiteColor];
    }
    _labelStreamTotalDuration.font = [UIFont fontWithName:@"HelveticaNeue" size:13.0];
    _labelStreamTotalDuration.hidden = YES;
    [_viewCenteredOnBar addSubview:_labelStreamTotalDuration];
    
    /* sliderCurrentDuration */
    _sliderCurrentDuration = [[[UISlider alloc] initWithFrame:CGRectZero] autorelease];
    _sliderCurrentDuration.translatesAutoresizingMaskIntoConstraints = NO;
    _sliderCurrentDuration.minimumValue = 0.0;
    _sliderCurrentDuration.value = 0.0;
    _sliderCurrentDuration.continuous = YES;
    [_sliderCurrentDuration addTarget:self action:@selector(onSliderCurrentDurationTouched:) forControlEvents:UIControlEventTouchDown];
    [_sliderCurrentDuration addTarget:self action:@selector(onSliderCurrentDurationTouchedOut:) forControlEvents:UIControlEventTouchUpInside];
    [_sliderCurrentDuration addTarget:self action:@selector(onSliderCurrentDurationTouchedOut:) forControlEvents:UIControlEventTouchUpOutside];
    [_sliderCurrentDuration addTarget:self action:@selector(onSliderCurrentDurationChanged:) forControlEvents:UIControlEventValueChanged];
    _sliderCurrentDuration.hidden = YES;
    _labelStreamCurrentTime.textColor = [UIColor darkGrayColor];
    [_viewCenteredOnBar addSubview:_sliderCurrentDuration];
    
    /* Toolbar on top: _barButtonContainer */
    UIBarButtonItem *_barButtonContainer = [[[UIBarButtonItem alloc] initWithCustomView:_viewCenteredOnBar] autorelease];
    [toolBarItems addObject:_barButtonContainer];
    
    /* Toolbar on top: _barButtonSpaceRightFlexible */
    UIBarButtonItem *_barButtonSpaceRightFlexible = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:NULL action:NULL] autorelease];
    [toolBarItems addObject:_barButtonSpaceRightFlexible];
    
    /* Toolbar on top: _barButtonScale */
    UIBarButtonItem *_barButtonSpaceRightFixed = [[[UIBarButtonItem alloc] initWithTitle:@"      " style:UIBarButtonItemStylePlain target:NULL action:NULL] autorelease];
    [toolBarItems addObject:_barButtonSpaceRightFixed];
    
    [_toolBar setItems:toolBarItems];
    
    //Set Autolayout constraints for bar elements
    NSDictionary *metricsBarSubviews = @{@"bar_subview_height": @(heightSubviewOnBar), @"bar_time_label_width": @(wStrmTimeLabelsOnBar)};
    
    // align _labelBarTitle from the left and right
    [_viewCenteredOnBar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_labelBarTitle]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_labelBarTitle)]];
    // align _labelBarTitle from the top
    [_viewCenteredOnBar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-6-[_labelBarTitle(==bar_subview_height)]" options:0 metrics:metricsBarSubviews views:NSDictionaryOfVariableBindings(_labelBarTitle)]];
    
    // align _activityIndicator center with superview
    CGSize textSizeTitle = [_labelBarTitle.text sizeWithAttributes:@{NSFontAttributeName:[_labelBarTitle font]}];
    float leftMarginActivityIndicator = 15.0;
    [_viewCenteredOnBar addConstraint:[NSLayoutConstraint constraintWithItem:_activityIndicator attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_viewCenteredOnBar attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:-(textSizeTitle.width/2.0 + leftMarginActivityIndicator)]];
    // align _activityIndicator from the top
    [_viewCenteredOnBar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-7-[_activityIndicator]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_activityIndicator)]];
    
    // align _viewCenteredOnBar from the left and right
    [_toolBar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-62-[_viewCenteredOnBar]-62-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_viewCenteredOnBar)]];
    // align _viewCenteredOnBar from the top
    [_toolBar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-6-[_viewCenteredOnBar]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_viewCenteredOnBar)]];
    // _viewCenteredOnBar height constraint
    [_toolBar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_viewCenteredOnBar(==33)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_viewCenteredOnBar)]];
    
    // align buttonDone from the left and right
    [_toolBar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-4-[buttonDone(==44)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(buttonDone)]];
    // align buttonDone from the top
    [_toolBar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-6-[buttonDone(==33)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(buttonDone)]];
    
    // align _labelStreamCurrentTime from the top
    [_viewCenteredOnBar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-6-[_labelStreamCurrentTime(==bar_subview_height)]" options:0 metrics:metricsBarSubviews views:NSDictionaryOfVariableBindings(_labelStreamCurrentTime)]];
    
    // align subviews of viewCenteredOnBar from the left & top
    [_viewCenteredOnBar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[_labelStreamCurrentTime(==bar_time_label_width)]-4-[_sliderCurrentDuration]-4-[_labelStreamTotalDuration(==bar_time_label_width)]-8-|" options:NSLayoutFormatAlignAllCenterY metrics:metricsBarSubviews views:NSDictionaryOfVariableBindings(_labelStreamCurrentTime, _sliderCurrentDuration, _labelStreamTotalDuration)]];
}

- (void)createUIFullScreenPanel {
    /* Control panel: _viewControlPanel */
    _viewControlPanel = [[UIView alloc] initWithFrame:CGRectZero];
    _viewControlPanel.translatesAutoresizingMaskIntoConstraints = NO;
    
    if ([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] != NSOrderedAscending) {
        //running on iOS 8.0 or higher
        if (!UIAccessibilityIsReduceTransparencyEnabled()) {
            _viewControlPanel.backgroundColor = [UIColor clearColor];
            
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
            UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            blurEffectView.translatesAutoresizingMaskIntoConstraints = NO;
            [_viewControlPanel addSubview:blurEffectView];
            
            // align blurEffectView from the left and right
            [_viewControlPanel addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[blurEffectView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(blurEffectView)]];
            
            // align blurEffectView from the top and bottom
            [_viewControlPanel addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[blurEffectView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(blurEffectView)]];
        }  
        else {
            _viewControlPanel.backgroundColor = [UIColor whiteColor];
        }
    } else {
        _viewControlPanel.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    }
    
    /* Control panel: _buttonPanelPP */
    _buttonPanelPP = [[[UIButton alloc] initWithFrame:CGRectZero] autorelease];
    _buttonPanelPP.translatesAutoresizingMaskIntoConstraints = NO;
    _buttonPanelPP.showsTouchWhenHighlighted = YES;
    _buttonPanelPP.tag = PANEL_BUTTON_TAG_PP_TOGGLE;
    [_buttonPanelPP addTarget:self action:@selector(onControlPanelButtonsTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_viewControlPanel addSubview:_buttonPanelPP];
    
    // center _buttonPanelPP horizontally in _viewControlPanel
    [_viewControlPanel addConstraint:[NSLayoutConstraint constraintWithItem:_buttonPanelPP attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_viewControlPanel attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    
    // align _buttonPanelPP from the top
    [_viewControlPanel addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-13-[_buttonPanelPP(==27)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_buttonPanelPP)]];
    
    // width constraint
    [_viewControlPanel addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_buttonPanelPP(==30)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_buttonPanelPP)]];
    
    /* Control panel: _buttonPanelInfo */
    _buttonPanelInfo = [[[UIButton alloc] initWithFrame:CGRectZero] autorelease];
    _buttonPanelInfo.translatesAutoresizingMaskIntoConstraints = NO;
    _buttonPanelInfo.showsTouchWhenHighlighted = YES;
    _buttonPanelInfo.tag = PANEL_BUTTON_TAG_INFO;
    [_buttonPanelInfo addTarget:self action:@selector(onControlPanelButtonsTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_viewControlPanel addSubview:_buttonPanelInfo];
   
    // align _buttonPanelInfo from the right
    [_viewControlPanel addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_buttonPanelInfo(==40)]-28-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_buttonPanelInfo)]];
    
    // align _buttonPanelInfo from the top
    [_viewControlPanel addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-2-[_buttonPanelInfo(==40)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_buttonPanelInfo)]];
    
    int adjustmentIfNoRecord = 0;
#ifdef VK_RECORDING_CAPABILITY
    /* Control panel: _buttonPanelRecord */
    adjustmentIfNoRecord = (_recordingEnabled) ? 50:0;
    _buttonPanelRecord = [[[UIButton alloc] initWithFrame:CGRectZero] autorelease];
    _buttonPanelRecord.imageEdgeInsets = UIEdgeInsetsMake(-8.0, -22.0, 0.0, 0.0);
    _buttonPanelRecord.translatesAutoresizingMaskIntoConstraints = NO;
    _buttonPanelRecord.showsTouchWhenHighlighted = YES;
    _buttonPanelRecord.contentMode = UIViewContentModeCenter;
    _buttonPanelRecord.tag = PANEL_BUTTON_TAG_RECORD;
    _buttonPanelRecord.hidden = YES;
    [_buttonPanelRecord setImage:[UIImage imageNamed:@"VKImages.bundle/vk-panel-button-record.png"] forState:UIControlStateNormal];
    [_buttonPanelRecord addTarget:self action:@selector(onControlPanelButtonsTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_viewControlPanel addSubview:_buttonPanelRecord];
    
    // align _buttonPanelRecord from the right
    [_viewControlPanel addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_buttonPanelRecord(==64)]-4-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_buttonPanelRecord)]];
    
    // align _buttonPanelRecord from the top
    [_viewControlPanel addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-44-[_buttonPanelRecord(==48)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_buttonPanelRecord)]];
    
#endif
    
    /* Control panel: _imgViewSpeaker */
    _imgViewSpeaker = [[[UIImageView alloc] initWithFrame:CGRectZero] autorelease];
    [_viewControlPanel addSubview:_imgViewSpeaker];
    _imgViewSpeaker.translatesAutoresizingMaskIntoConstraints = NO;
    
    // align _imgViewSpeaker from the left
    [_viewControlPanel addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[_imgViewSpeaker(==21)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_imgViewSpeaker)]];
    
    // align _imgViewSpeaker from the top
    [_viewControlPanel addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-55-[_imgViewSpeaker(==23)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_imgViewSpeaker)]];
    
    /* Control panel: _labelElapsedTime */
    _labelElapsedTime = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    _labelElapsedTime.translatesAutoresizingMaskIntoConstraints = NO;
    _labelElapsedTime.contentMode = UIViewContentModeLeft;
    _labelElapsedTime.text = @"00:00";
    _labelElapsedTime.textAlignment = NSTextAlignmentLeft;
    _labelElapsedTime.backgroundColor = [UIColor clearColor];
    _labelElapsedTime.opaque = NO;
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending) {
        //running on iOS 7.0 or higher
        _labelElapsedTime.textColor = [UIColor darkGrayColor];
    } else {
        _labelElapsedTime.textColor = [UIColor colorWithRed:0.906 green:0.906 blue:0.906 alpha:1.000];
    }
    _labelElapsedTime.font = [UIFont fontWithName:@"HelveticaNeue" size:16];
    [_viewControlPanel addSubview:_labelElapsedTime];
    
    // align _labelElapsedTime from the left
    [_viewControlPanel addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[_labelElapsedTime(==64)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_labelElapsedTime)]];
    
    // align _labelElapsedTime from the top
    [_viewControlPanel addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-16-[_labelElapsedTime(==21)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_labelElapsedTime)]];
    
    /* Control panel: _sliderVolume */
    _sliderVolume = [[[MPVolumeView alloc] initWithFrame:CGRectZero] autorelease];
    _sliderVolume.translatesAutoresizingMaskIntoConstraints = NO;
    [_viewControlPanel addSubview:_sliderVolume];
    
    // align _sliderVolume from the left
    [_viewControlPanel addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-53-[_sliderVolume]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_sliderVolume)]];
    
    // align _sliderVolume from the top
    [_viewControlPanel addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-56-[_sliderVolume(==23)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_sliderVolume)]];
    
    // width constraint
    NSLayoutConstraint *sliderVolumeConstraitWidth = [NSLayoutConstraint constraintWithItem:_sliderVolume attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:NULL attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:(219.0 - adjustmentIfNoRecord)];
    
    sliderVolumeConstraitWidth.identifier = @"_sliderVolume-width";
    [_viewControlPanel addConstraint:sliderVolumeConstraitWidth];
    
    /* set the images */
    _imgViewControlPanel.image = [UIImage imageNamed:@"VKImages.bundle/vk-panel-bg.png"];
    _imgViewSpeaker.image = [UIImage imageNamed:@"VKImages.bundle/vk-panel-button-speaker.png"];
    [_buttonPanelPP setImage:[UIImage imageNamed:@"VKImages.bundle/vk-panel-button-play.png"] forState:UIControlStateNormal];
    [_buttonPanelInfo setImage:[UIImage imageNamed:@"VKImages.bundle/vk-panel-button-info.png"] forState:UIControlStateNormal];
}

- (void)createUIEmbedded {
    [self createUIEmbeddedBar];
    [self createUIEmbeddedPanel];

    _labelStatusEmbedded = [[UILabel alloc] initWithFrame:CGRectZero];
    _labelStatusEmbedded.translatesAutoresizingMaskIntoConstraints = NO;
    _labelStatusEmbedded.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
    _labelStatusEmbedded.backgroundColor = [UIColor clearColor];
    _labelStatusEmbedded.textColor = [UIColor darkGrayColor];
    _labelStatusEmbedded.lineBreakMode = NSLineBreakByTruncatingTail;
    _labelStatusEmbedded.minimumScaleFactor = 0.5;
    _labelStatusEmbedded.textAlignment = NSTextAlignmentCenter;
    _labelStatusEmbedded.text = [self staturBarInitialText];
}

- (void)createUIEmbeddedBar {
    float viewWidth = self.view.bounds.size.width;
    _viewBarEmbedded = [[UIView alloc] initWithFrame:CGRectZero];
    _viewBarEmbedded.translatesAutoresizingMaskIntoConstraints = NO;
    _viewBarEmbedded.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.6];
    
    _labelBarEmbedded = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    _labelBarEmbedded.translatesAutoresizingMaskIntoConstraints = NO;
    _labelBarEmbedded.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
    _labelBarEmbedded.backgroundColor = [UIColor clearColor];
    _labelBarEmbedded.textColor = [UIColor darkGrayColor];
    _labelBarEmbedded.lineBreakMode = NSLineBreakByTruncatingTail;
    _labelBarEmbedded.minimumScaleFactor = 0.5;
    [_viewBarEmbedded addSubview:_labelBarEmbedded];
    
    // align _labelBarEmbedded from the left and right
    [_viewBarEmbedded addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[_labelBarEmbedded]-43-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_labelBarEmbedded)]];
    // align _labelBarEmbedded from the top
    [_viewBarEmbedded addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_labelBarEmbedded(==30)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_labelBarEmbedded)]];
    
    float activityWidth = 20.0;
    float marginX = 8.0;
    _activityIndicatorEmbedded = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
    _activityIndicatorEmbedded.translatesAutoresizingMaskIntoConstraints = NO;
    _activityIndicatorEmbedded.hidesWhenStopped = YES;
    [_viewBarEmbedded addSubview:_activityIndicatorEmbedded];
    
    NSDictionary *metricsActivityIndicatorEmbedded = @{@"activity_indicator_embedded_right_margin": @((viewWidth - (activityWidth + marginX))), @"activity_indicator_embedded_width": @(activityWidth)};
    // align _activityIndicatorEmbedded from the left
    [_viewBarEmbedded addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_activityIndicatorEmbedded]-8-|" options:0 metrics:metricsActivityIndicatorEmbedded views:NSDictionaryOfVariableBindings(_activityIndicatorEmbedded)]];
    // align _activityIndicatorEmbedded from the top
    [_viewBarEmbedded addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[_activityIndicatorEmbedded]" options:0 metrics:metricsActivityIndicatorEmbedded views:NSDictionaryOfVariableBindings(_activityIndicatorEmbedded)]];

    _labelElapsedTimeEmbedded = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    _labelElapsedTimeEmbedded.translatesAutoresizingMaskIntoConstraints = NO;
    _labelElapsedTimeEmbedded.text = @"00:00";
    _labelElapsedTimeEmbedded.textAlignment = NSTextAlignmentCenter;
    _labelElapsedTimeEmbedded.backgroundColor = [UIColor clearColor];
    _labelElapsedTimeEmbedded.textColor = [UIColor darkGrayColor];
    _labelElapsedTimeEmbedded.font = [UIFont fontWithName:@"HelveticaNeue" size:13];
    [_viewBarEmbedded addSubview:_labelElapsedTimeEmbedded];
    
    // align _labelElapsedTimeEmbedded from the right
    [_viewBarEmbedded addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_labelElapsedTimeEmbedded(==35)]-8-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_labelElapsedTimeEmbedded)]];
    // align _labelElapsedTimeEmbedded from the top
    [_viewBarEmbedded addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-3-[_labelElapsedTimeEmbedded(==23)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_labelElapsedTimeEmbedded)]];
}

- (void)createUIEmbeddedPanel {
    
    _viewControlPanelEmbedded = [[UIView alloc] initWithFrame:CGRectZero];
    _viewControlPanelEmbedded.translatesAutoresizingMaskIntoConstraints = NO;
    _viewControlPanelEmbedded.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.6];
    
    float marginX = 8.0;
    float marginY = 3.0;
    float buttonWidth = 24.0;
    float labelWidth = 35.0;
    float labelHeight = 23.0;
    
    NSDictionary *metricsEmbeddedPanel = @{@"panel_embedded_x_margin": @(marginX), @"panel_embedded_y_margin": @(marginY),
                                           @"button_panel_width" : @(buttonWidth),
                                           @"label_width" : @(labelWidth), @"label_height" : @(labelHeight)};
    
    _buttonPanelPPEmbedded = [[[UIButton alloc] initWithFrame:CGRectZero] autorelease];
    _buttonPanelPPEmbedded.translatesAutoresizingMaskIntoConstraints = NO;
    _buttonPanelPPEmbedded.showsTouchWhenHighlighted = YES;
    _buttonPanelPPEmbedded.tag = PANEL_BUTTON_TAG_PP_TOGGLE;
    _buttonPanelPPEmbedded.contentMode = UIViewContentModeCenter;
    [_buttonPanelPPEmbedded addTarget:self action:@selector(onControlPanelButtonsTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_viewControlPanelEmbedded addSubview:_buttonPanelPPEmbedded];
    
    _labelStreamCurrentTimeEmbedded = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    _labelStreamCurrentTimeEmbedded.translatesAutoresizingMaskIntoConstraints = NO;
    _labelStreamCurrentTimeEmbedded.font = [UIFont fontWithName:@"HelveticaNeue" size:13];
    _labelStreamCurrentTimeEmbedded.backgroundColor = [UIColor clearColor];
    _labelStreamCurrentTimeEmbedded.textColor = [UIColor darkGrayColor];
    _labelStreamCurrentTimeEmbedded.textAlignment = NSTextAlignmentCenter;
    [_viewControlPanelEmbedded addSubview:_labelStreamCurrentTimeEmbedded];
    
    _buttonFullScreenEmbedded = [[[UIButton alloc] initWithFrame:CGRectZero] autorelease];
    _buttonFullScreenEmbedded.translatesAutoresizingMaskIntoConstraints = NO;
    _buttonFullScreenEmbedded.showsTouchWhenHighlighted = YES;
    _buttonFullScreenEmbedded.tag = PANEL_BUTTON_TAG_FULLSCREEN;
    _buttonFullScreenEmbedded.contentMode = UIViewContentModeCenter;
    [_buttonFullScreenEmbedded addTarget:self action:@selector(onControlPanelButtonsTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_viewControlPanelEmbedded addSubview:_buttonFullScreenEmbedded];

    _labelStreamTotalDurationEmbedded = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    _labelStreamTotalDurationEmbedded.translatesAutoresizingMaskIntoConstraints = NO;
    _labelStreamTotalDurationEmbedded.font = [UIFont fontWithName:@"HelveticaNeue" size:13];
    _labelStreamTotalDurationEmbedded.backgroundColor = [UIColor clearColor];
    _labelStreamTotalDurationEmbedded.textColor = [UIColor darkGrayColor];
    _labelStreamTotalDurationEmbedded.textAlignment = NSTextAlignmentCenter;
    [_viewControlPanelEmbedded addSubview:_labelStreamTotalDurationEmbedded];
    
    _sliderCurrentDurationEmbedded = [[[UISlider alloc] initWithFrame:CGRectZero] autorelease];
    _sliderCurrentDurationEmbedded.translatesAutoresizingMaskIntoConstraints = NO;
    _sliderCurrentDurationEmbedded.minimumValue = 0.0;
    _sliderCurrentDurationEmbedded.value = 0.0;
    _sliderCurrentDurationEmbedded.continuous = YES;
    [_sliderCurrentDurationEmbedded addTarget:self action:@selector(onSliderCurrentDurationTouched:) forControlEvents:UIControlEventTouchDown];
    [_sliderCurrentDurationEmbedded addTarget:self action:@selector(onSliderCurrentDurationTouchedOut:) forControlEvents:UIControlEventTouchUpInside];
    [_sliderCurrentDurationEmbedded addTarget:self action:@selector(onSliderCurrentDurationTouchedOut:) forControlEvents:UIControlEventTouchUpOutside];
    [_sliderCurrentDurationEmbedded addTarget:self action:@selector(onSliderCurrentDurationChanged:) forControlEvents:UIControlEventValueChanged];
    _sliderCurrentDurationEmbedded.hidden = YES;
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedDescending) {
        [_sliderCurrentDurationEmbedded setMinimumTrackImage:_imgSliderMin forState:UIControlStateNormal];
        [_sliderCurrentDurationEmbedded setMaximumTrackImage:_imgSliderMax forState:UIControlStateNormal];
        [_sliderCurrentDurationEmbedded setThumbImage:_imgSliderThumb forState:UIControlStateNormal];
    }
    [_viewControlPanelEmbedded addSubview:_sliderCurrentDurationEmbedded];
 
    [_viewControlPanelEmbedded addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-panel_embedded_y_margin-[_buttonPanelPPEmbedded(==button_panel_width)]" options:0 metrics:metricsEmbeddedPanel views:NSDictionaryOfVariableBindings(_buttonPanelPPEmbedded)]];
    
    // align subviews of _viewControlPanelEmbedded from the left & top
    [_viewControlPanelEmbedded addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-panel_embedded_x_margin-[_buttonPanelPPEmbedded(==button_panel_width)]-8-[_labelStreamCurrentTimeEmbedded(==label_width)]-4-[_sliderCurrentDurationEmbedded]-4-[_labelStreamTotalDurationEmbedded(<=label_width)]-8-[_buttonFullScreenEmbedded(==button_panel_width)]-panel_embedded_x_margin-|" options:NSLayoutFormatAlignAllCenterY metrics:metricsEmbeddedPanel views:NSDictionaryOfVariableBindings(_buttonPanelPPEmbedded, _labelStreamCurrentTimeEmbedded, _buttonFullScreenEmbedded, _labelStreamTotalDurationEmbedded, _sliderCurrentDurationEmbedded)]];
    
    [_buttonPanelPPEmbedded setImage:[UIImage imageNamed:@"VKImages.bundle/vk-panel-button-play-embedded.png"] forState:UIControlStateNormal];
    [_buttonFullScreenEmbedded setImage:[UIImage imageNamed:@"VKImages.bundle/vk-bar-button-zoom-out.png"] forState:UIControlStateNormal];
}

- (void)createUICenter {

    [super createUICenter];
    
    /* Center subviews: _imgViewExternalScreen */
    int hExtScreen = 122.0;
    int wExtScreen = 91.0;
    
    NSDictionary *metricsImgViewExternalScreen = @{@"imgview_extscreen_height": @(hExtScreen), @"imgview_extscreen_width": @(wExtScreen)};

    _imgViewExternalScreen = [[UIImageView alloc] initWithFrame:CGRectZero];
    _imgViewExternalScreen.translatesAutoresizingMaskIntoConstraints = NO;
    _imgViewExternalScreen.contentMode = UIViewContentModeScaleAspectFit;
    _imgViewExternalScreen.hidden = YES;
    _imgViewExternalScreen.opaque = NO;
    _imgViewExternalScreen.userInteractionEnabled = YES;
    [self.view insertSubview:_imgViewExternalScreen atIndex:0];
    
    // center _imgViewExternalScreen horizontally in self.view
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_imgViewExternalScreen attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    
    // center _imgViewExternalScreen vertically in self.view
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_imgViewExternalScreen attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    
    // width constraint
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_imgViewExternalScreen(==imgview_extscreen_height)]" options:0 metrics:metricsImgViewExternalScreen views:NSDictionaryOfVariableBindings(_imgViewExternalScreen)]];
    
    // height constraint
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_imgViewExternalScreen(==imgview_extscreen_width)]" options:0 metrics:metricsImgViewExternalScreen views:NSDictionaryOfVariableBindings(_imgViewExternalScreen)]];
    
    /* set the images */
    _imgViewExternalScreen.image = [UIImage imageNamed:@"VKImages.bundle/vk-external-screen.png"];
}

- (void)addUIFullScreen {
    if (![_viewControlPanel superview]) {
        [self.view addSubview:_viewControlPanel];
        
        // center _viewControlPanel horizontally in self.view
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_viewControlPanel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
        
        // align _viewControlPanel from the bottom
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_viewControlPanel(==93)]-3-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_viewControlPanel)]];
        
        // width constraint
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_viewControlPanel(==314)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_viewControlPanel)]];
    }
    
    if (![_toolBar superview]) {
        [self.view addSubview:_toolBar];
        
        // align _toolBar from the left and right
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_toolBar]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_toolBar)]];
        
        //_toolBar height constant
        NSLayoutConstraint *toolBarConstaintHeight = [NSLayoutConstraint constraintWithItem:_toolBar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:NULL attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:44.0];
        [self.view addConstraint:toolBarConstaintHeight];
        
        // align _toolBar from the top
        NSLayoutConstraint *toolBarConstaintTop = [NSLayoutConstraint constraintWithItem:_toolBar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
        toolBarConstaintTop.identifier = @"toolbar-top-margin";
        [self.view addConstraint:toolBarConstaintTop];
    }
}

- (void)removeUIFullScreen {
    if ([_viewControlPanel superview])
        [_viewControlPanel removeFromSuperview];
    
    if ([_toolBar superview])
        [_toolBar removeFromSuperview];
}

- (void)addUIEmbedded {
    if (![_viewControlPanelEmbedded superview]) {
        [self.view addSubview:_viewControlPanelEmbedded];
        
        // align _viewBarEmbedded from the left and right
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_viewControlPanelEmbedded]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_viewControlPanelEmbedded)]];
        // align _viewBarEmbedded from the top
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_viewControlPanelEmbedded(==30)]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_viewControlPanelEmbedded)]];
    }
    
    if (![_viewBarEmbedded superview]) {
        [self.view addSubview:_viewBarEmbedded];
        
        // align _viewBarEmbedded from the left and right
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_viewBarEmbedded]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_viewBarEmbedded)]];
        // align _viewBarEmbedded from the top
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_viewBarEmbedded(==30)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_viewBarEmbedded)]];
    }
    
    if (![_labelStatusEmbedded superview]) {
        [self.view addSubview:_labelStatusEmbedded];
        
        int hLabel = 30.0;
        int wLabel = 120.0;
        NSDictionary *metrics = @{@"label_height": @(hLabel), @"label_width": @(wLabel)};
        
        // center _labelStatusEmbedded horizontally in self.view
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_labelStatusEmbedded attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
        // center _labelStatusEmbedded vertically in self.view
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_labelStatusEmbedded attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
        // width constraint
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_labelStatusEmbedded(==label_width)]" options:0 metrics:metrics views:NSDictionaryOfVariableBindings(_labelStatusEmbedded)]];
        // height constraint
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_labelStatusEmbedded(==label_height)]" options:0 metrics:metrics views:NSDictionaryOfVariableBindings(_labelStatusEmbedded)]];
    }
}

- (void)removeUIEmbedded {
    if ([_viewControlPanelEmbedded superview])
        [_viewControlPanelEmbedded removeFromSuperview];
    
    if ([_viewBarEmbedded superview])
        [_viewBarEmbedded removeFromSuperview];
    
    if ([_labelStatusEmbedded superview])
        [_labelStatusEmbedded removeFromSuperview];
}

- (void)updateBarWithDurationState:(VKError) state {

    BOOL value = NO;
    if (state == kVKErrorNone) {
        value = YES;
    }
    
    //Fullscreen
    [_labelBarTitle setHidden:value];
    [_labelStreamCurrentTime setHidden:!value];
    [_labelStreamTotalDuration setHidden:!value];
    [_sliderCurrentDuration setHidden:!value];
    
    //Embedded
    [_labelStreamCurrentTimeEmbedded setHidden:!value];
    [_labelStreamTotalDurationEmbedded setHidden:!value];
    [_sliderCurrentDurationEmbedded setHidden:!value];
}

- (void)useContainerViewControllerAnimated:(BOOL)animated {
    UIViewController *currentVc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    UIViewController *topVc = nil;

    if (currentVc) {
        if ([currentVc isKindOfClass:[UINavigationController class]]) {
            topVc = [(UINavigationController *)currentVc topViewController];
        } else if ([currentVc isKindOfClass:[UITabBarController class]]) {
            topVc = [(UITabBarController *)currentVc selectedViewController];
        } else if ([currentVc presentedViewController]) {
            topVc = [currentVc presentedViewController];
        } else if ([currentVc isKindOfClass:[UIViewController class]]) {
            topVc = currentVc;
        } else {
            VKLog(kVKLogLevelDecoder, @"Expected a view controller but not found...");
            return;
        }
    } else {
        VKLog(kVKLogLevelDecoder, @"Expected a view controller but not found...");
        return;
    }
    
    
    [self.scrollView setZoomScale:1.0 animated:NO];
    [self.scrollView setDisableCenterViewNow:YES];

    [self.view.superview bringSubviewToFront:self.view];
    
    self.view.backgroundColor = [UIColor clearColor];
    self.scrollView.backgroundColor = [UIColor clearColor];
    
    float duration = (animated) ? 0.5 : 0.0;
    
    UIWindow *keyWindow = [[[UIApplication sharedApplication] windows] lastObject];
    id windowActive = keyWindow;
    if ([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending) {
        //running on iOS 7.x
        windowActive = [[keyWindow subviews] objectAtIndex:0];
    }
    
    CGRect newRectToWindow = [windowActive convertRect:self.view.frame fromView:self.view.superview];
    VKFullscreenContainer *fsContainerVc = [[[VKFullscreenContainer alloc] initWithPlayerController:self
                                                                                         windowRect:newRectToWindow] autorelease];
    [self removeUIEmbedded];
    
    CGRect bounds = [[UIScreen mainScreen] bounds];
    
    if ([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending) {
        //running on only iOS 7.x
        UIInterfaceOrientation orientation = (UIInterfaceOrientation)[[UIDevice currentDevice] orientation];
        if (UIDeviceOrientationIsValidInterfaceOrientation(orientation)) {
            if (UIInterfaceOrientationIsLandscape(orientation)) {
                bounds =  CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.height, bounds.size.width);
            }
        } else {
            if (UIInterfaceOrientationIsLandscape(topVc.interfaceOrientation)) {
                bounds =  CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.height, bounds.size.width);
            }
        }
    }
    
    __block NSLayoutConstraint *constraintTopByWin, *constraintLeftByWin, *constraintWidthByWin, *constraintHeightByWin;
    
    [topVc presentViewController:fsContainerVc animated:YES completion:^{
        
        [windowActive addSubview:self.view];
        
        if (![self.view translatesAutoresizingMaskIntoConstraints]) {
            //Set Autolayout constraints self.view
            
            // align self.view from the top
            constraintTopByWin = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:windowActive attribute:NSLayoutAttributeTop multiplier:1.0 constant:newRectToWindow.origin.y];
            [windowActive addConstraint:constraintTopByWin];
            
            // align self.view from the left
            constraintLeftByWin = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:windowActive attribute:NSLayoutAttributeLeft multiplier:1.0 constant:newRectToWindow.origin.x];
            [windowActive addConstraint:constraintLeftByWin];
            
            // self.view width constant
            constraintWidthByWin = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:NULL attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:newRectToWindow.size.width];
            [windowActive addConstraint:constraintWidthByWin];
            
            // self.view height constant
            constraintHeightByWin = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:NULL attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:newRectToWindow.size.height];
            [windowActive addConstraint:constraintHeightByWin];
            
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
        }
        
        [UIView animateWithDuration:duration animations:^{
            
            if (![self.view translatesAutoresizingMaskIntoConstraints]) {
                //view has autolayout
                constraintTopByWin.constant = 0.0;
                constraintLeftByWin.constant = 0.0;
                constraintWidthByWin.constant = bounds.size.width;
                constraintHeightByWin.constant = bounds.size.height;
                [self.view setNeedsLayout];
                [self.view layoutIfNeeded];
            } else {
                self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                self.view.frame = bounds;
            }
            if (_mainScreenIsMobile) {
                _renderView.frame = [_renderView exactFrameRectForSize:self.view.bounds.size fillScreen:[self fillScreen]];
                [_renderView updateOpenGLFrameSizes];
            }
            
        } completion:^(BOOL finished) {
            
            _containerVc = [fsContainerVc retain];
            
            if (_controlStyle != kVKPlayerControlStyleNone) {
                _toolBar.alpha = 0.0;
                _viewControlPanel.alpha = 0.0;
                _panelIsHidden = YES;
                [self addUIFullScreen];
                _controlStyle = kVKPlayerControlStyleFullScreen;
            }
            
            float statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
            if ([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending) {
                //running on only iOS 7.x
                UIInterfaceOrientation orientation = (UIInterfaceOrientation)[[UIDevice currentDevice] orientation];
                if (UIDeviceOrientationIsValidInterfaceOrientation(orientation)) {
                    if (UIInterfaceOrientationIsLandscape(orientation)) {
                        statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.width;
                    }
                } else {
                    if (UIInterfaceOrientationIsLandscape(topVc.interfaceOrientation)) {
                        statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.width;
                    }
                }
            }
            
            _toolBar.delegate = (id<UIToolbarDelegate>)fsContainerVc;
            
            NSArray *constraints = [self.view constraints];
            NSLayoutConstraint *constraitTop = nil;
            for (NSLayoutConstraint *constraint in constraints) {
                if ([constraint.identifier isEqualToString:@"toolbar-top-margin"]) {
                    constraitTop = constraint;
                    break;
                }
            }
            if (_statusBarHidden) {
                constraitTop.constant = 0.0;
            } else {
                constraitTop.constant = (statusBarHeight != 0) ? statusBarHeight : 20.0;
            }
            
            [fsContainerVc.view addSubview:self.view];
            
            UIView *playerView = self.view;
            // align _playerController.view from the left and right
            [fsContainerVc.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[playerView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(playerView)]];
            
            // align _playerController.view from the top and bottom
            [fsContainerVc.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[playerView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(playerView)]];
            
            if (_mainScreenIsMobile) {
                [self.scrollView setDisableCenterViewNow:NO];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:kVKPlayerDidEnterFullscreenNotification object:nil userInfo:nil];
        }];
    }];
}

- (void)addScreenControlGesturesToContainerView:(UIView *)viewContainer renderView:(UIView *)viewRender {
    if (viewContainer) {
        _singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        _singleTapGestureRecognizer.numberOfTapsRequired = 1;
        [viewContainer addGestureRecognizer:_singleTapGestureRecognizer];

        _longGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [viewContainer addGestureRecognizer:_longGestureRecognizer];
        
        [_singleTapGestureRecognizer requireGestureRecognizerToFail:_longGestureRecognizer];
    }
    
    if (viewRender) {
        _doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        _doubleTapGestureRecognizer.numberOfTapsRequired = 2;
        [viewRender addGestureRecognizer:_doubleTapGestureRecognizer];
        
        [_singleTapGestureRecognizer requireGestureRecognizerToFail:_doubleTapGestureRecognizer];
    }
}

- (void)removeScreenControlGesturesFromContainerView:(UIView *)viewContainer renderView:(UIView *)viewRender {
    if (_singleTapGestureRecognizer) {
        [viewContainer removeGestureRecognizer:_singleTapGestureRecognizer];
        [_singleTapGestureRecognizer release];
        _singleTapGestureRecognizer = nil;
    }
    
    if (_longGestureRecognizer) {
        [viewContainer removeGestureRecognizer:_longGestureRecognizer];
        [_longGestureRecognizer release];
        _longGestureRecognizer = nil;
    }
    
    if (_doubleTapGestureRecognizer) {
        [viewRender removeGestureRecognizer:_doubleTapGestureRecognizer];
        [_doubleTapGestureRecognizer release];
        _doubleTapGestureRecognizer = nil;
    }
}

- (void)addGesturesToInfoView:(UIView *)viewGesture {
    _closeInfoViewGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideInfoView)];
    _closeInfoViewGestureRecognizer.numberOfTapsRequired = 1;
    [viewGesture addGestureRecognizer:_closeInfoViewGestureRecognizer];
}

- (void)removeGesturesFromInfoView:(UIView *)viewGesture {
    if (_closeInfoViewGestureRecognizer) {
        [viewGesture removeGestureRecognizer:_closeInfoViewGestureRecognizer];
    }
}

#ifdef VK_RECORDING_CAPABILITY
- (void)setRecordingEnabled:(BOOL)recordingEnabled {
    [super setRecordingEnabled:recordingEnabled];
    [_buttonPanelRecord setHidden:!recordingEnabled];
    
    NSArray *constraints = [_viewControlPanel constraints];
    NSLayoutConstraint *constraitWidth = nil;
    for (NSLayoutConstraint *constraint in constraints) {
        if ([constraint.identifier isEqualToString:@"_sliderVolume-width"]) {
            constraitWidth = constraint;
            break;
        }
    }
    
    if (_recordingEnabled) {
        constraitWidth.constant = 169.0;
    } else {
        constraitWidth.constant = 219.0;
    }
}
#endif

#pragma mark Subview actions

- (IBAction)onBarButtonsTapped:(id)sender {

    int tag = (int)[(UIBarButtonItem *)sender tag];

    if (tag == BAR_BUTTON_TAG_DONE) {
        if (_containerVc && ([NSStringFromClass([_containerVc class]) isEqualToString:@"VKPlayerViewController"])) {
            [[UIApplication sharedApplication] setStatusBarHidden:_statusBarHiddenBefore withAnimation:UIStatusBarAnimationFade];
            [self performSelector:@selector(stop) withObject:sender afterDelay:0.1];
        } else if (_containerVc) {
            [self performSelector:@selector(setFullScreen:) withObject:NULL afterDelay:0.1];
        }
    } else if (tag == BAR_BUTTON_TAG_SCALE) {
        [self performSelector:@selector(zoomInOut)];
    }
}

- (IBAction)onControlPanelButtonsTapped:(id)sender {
    int tag = (int)[(UIButton *)sender tag];
    if (tag == PANEL_BUTTON_TAG_PP_TOGGLE) {
        [self performSelector:@selector(togglePause)];
    } else if (tag == PANEL_BUTTON_TAG_INFO) {
        [self performSelector:@selector(showInfoView)];
    } else if (tag == PANEL_BUTTON_TAG_FULLSCREEN) {
        [self setFullScreen:YES];
        return;
    }
#ifdef VK_RECORDING_CAPABILITY
    else if (tag == PANEL_BUTTON_TAG_RECORD) {
        if (![_decodeManager recordingNow]) {
            [self startRecording];
        } else {
            [self stopRecording];
        }
    }
#endif
    [self showControlPanel:YES willExpire:YES];
}

- (void)showControlPanel:(BOOL)show willExpire:(BOOL)expire
{
    if (_controlStyle == kVKPlayerControlStyleNone) {
        float alpha = 0.0;
        _toolBar.alpha = alpha;
        _viewControlPanel.alpha = alpha;

        //Embedded
        _viewBarEmbedded.alpha = alpha;
        _viewControlPanelEmbedded.alpha = alpha;
        return;
    }

    if (!show && _sliderDurationCurrentTouched) {
        goto retry;
    }

    _panelIsHidden = !show;

    if (_timerPanelHidden && [_timerPanelHidden isValid]) {
        [_timerPanelHidden invalidate];
    }

    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone
                     animations:^{
                         CGFloat alpha = _panelIsHidden ? 0 : 1;

                         //Fullscreen
                         _toolBar.alpha = alpha;
                         _viewControlPanel.alpha = alpha;

                         //Embedded
                         _viewBarEmbedded.alpha = alpha;
                         _viewControlPanelEmbedded.alpha = alpha;
                     }
                     completion:nil];

retry:
    if (!_panelIsHidden && expire) {
        [_timerPanelHidden release];
        _timerPanelHidden = nil;
        _timerPanelHidden = [[NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(onTimerPanelHiddenFired:) userInfo:nil repeats:NO] retain];
    }
}

- (void)setPanelButtonsEnabled:(BOOL)enabled {
    //Fullscreen
    _buttonPanelPP.enabled = enabled;
    _buttonPanelInfo.enabled = enabled;
#ifdef VK_RECORDING_CAPABILITY
    _buttonPanelRecord.enabled = enabled;
#endif

    //Embedded
    _buttonPanelPPEmbedded.enabled = enabled;
    _buttonFullScreenEmbedded.enabled = enabled;
}

- (void)onSliderCurrentDurationTouched:(id) sender {
    _sliderDurationCurrentTouched = YES;
    [self stopDurationTimer];
}

- (void)onSliderCurrentDurationTouchedOut:(id) sender {
    _sliderDurationCurrentTouched = NO;

    if (_controlStyle == kVKPlayerControlStyleFullScreen) {
        [self setStreamCurrentDuration:_sliderCurrentDuration.value];
    } else {
        [self setStreamCurrentDuration:_sliderCurrentDurationEmbedded.value];
    }
    [self startDurationTimer];
    [self showControlPanel:YES willExpire:YES];
}

- (void)onSliderCurrentDurationChanged:(id) sender {
    _durationCurrent = [(UISlider*)sender value];
    _labelStreamCurrentTime.text = [NSString stringWithFormat:@"%02d:%02d", (int)_durationCurrent/60, ((int)_durationCurrent % 60)];
    _labelStreamCurrentTimeEmbedded.text =  _labelStreamCurrentTime.text;
}

#pragma mark Timer actions

- (void)stopDurationTimer {
    [super stopDurationTimer];
    _labelElapsedTime.text = @"00:00";
    _labelElapsedTimeEmbedded.text = _labelElapsedTime.text;
}

#pragma mark Timers callbacks

- (void)onTimerPanelHiddenFired:(NSTimer *)timer {
    [self showControlPanel:NO willExpire:YES];
}

- (void)onTimerElapsedFired:(NSTimer *)timer {
    [super onTimerElapsedFired:timer];
    _labelElapsedTime.text = [NSString stringWithFormat:@"%02d:%02d", _elapsedTime/60, (_elapsedTime % 60)];
    _labelElapsedTimeEmbedded.text = _labelElapsedTime.text;
}

- (void)onTimerDurationFired:(NSTimer *)timer {

    if (_decoderState == kVKDecoderStatePlaying) {
        _durationCurrent = (_decodeManager) ? [_decodeManager currentTime] : 0.0;
        if (!isnan(_durationCurrent) && ((_durationTotal - _durationCurrent) > -1.0)) {
            _labelStreamCurrentTime.text = [NSString stringWithFormat:@"%02d:%02d", (int)_durationCurrent/60, ((int)_durationCurrent % 60)];
            _labelStreamCurrentTimeEmbedded.text = _labelStreamCurrentTime.text;
            if(!_sliderDurationCurrentTouched) {
                _sliderCurrentDuration.value = _durationCurrent;
                _sliderCurrentDurationEmbedded.value = _sliderCurrentDuration.value;
            }
        }
    }
}

#pragma mark Public Player UI methods

- (void)zoomInOut:(UITapGestureRecognizer *)sender {
    [super zoomInOut:sender];
}

- (void)setControlStyle:(VKPlayerControlStyle)controlStyle {
    _controlStyle = controlStyle;
    if (_controlStyle == kVKPlayerControlStyleNone) {
        [self removeUIFullScreen];
        [self removeUIEmbedded];
        
    }
}

- (void)setFullScreen:(BOOL)value animated:(BOOL)animated {
    if (value && !_fullScreen) {
        _fullScreen = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:kVKPlayerWillEnterFullscreenNotification object:self userInfo:nil];
        
        _statusBarHiddenBefore = [[UIApplication sharedApplication] isStatusBarHidden];
        [[UIApplication sharedApplication] setStatusBarHidden:_statusBarHidden withAnimation:UIStatusBarAnimationFade];
        
        if (_containerVc &&
            ([NSStringFromClass([_containerVc class]) isEqualToString:@"VKPlayerViewController"])) {
            _controlStyle = kVKPlayerControlStyleFullScreen;
            
            float statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
            if ([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending) {
                //running on only iOS 7.x
                UIInterfaceOrientation orientation = (UIInterfaceOrientation)[[UIDevice currentDevice] orientation];
                if (UIDeviceOrientationIsValidInterfaceOrientation(orientation)) {
                    if (UIInterfaceOrientationIsLandscape(orientation)) {
                        statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.width;
                    }
                } else {
                    if (UIInterfaceOrientationIsLandscape(_containerVc.interfaceOrientation)) {
                        statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.width;
                    }
                }
            }
            
            [self removeUIEmbedded];
            [self addUIFullScreen];
            
            _toolBar.delegate = (id<UIToolbarDelegate>)_containerVc;
            
            NSArray *constraints = [self.view constraints];
            NSLayoutConstraint *constraitTop = nil;
            for (NSLayoutConstraint *constraint in constraints) {
                if ([constraint.identifier isEqualToString:@"toolbar-top-margin"]) {
                    constraitTop = constraint;
                    break;
                }
            }
            if (_statusBarHidden) {
                constraitTop.constant = 0.0;
            } else {
                constraitTop.constant = (statusBarHeight != 0) ? statusBarHeight : 20.0;
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kVKPlayerDidEnterFullscreenNotification object:self userInfo:nil];
            return;
        } else {
            [self useContainerViewControllerAnimated:animated];
        }
    } else if (!value && _fullScreen) {
        _fullScreen = NO;
        if (_containerVc &&
            ([NSStringFromClass([_containerVc class]) isEqualToString:@"VKPlayerViewController"])) {
            return;
        } else {
            if (_containerVc) {
                [[UIApplication sharedApplication] setStatusBarHidden:_statusBarHiddenBefore withAnimation:UIStatusBarAnimationFade];
                [[NSNotificationCenter defaultCenter] postNotificationName:kVKPlayerWillExitFullscreenNotification object:self userInfo:nil];
                
                [self removeUIFullScreen];
                
                [self.scrollView setZoomScale:1.0 animated:NO];
                [(VKFullscreenContainer *)_containerVc dismissContainerWithAnimated:animated completionHandler:NULL];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [_containerVc release];
                    _containerVc = nil;
                    _toolBar.delegate = nil;
                    
                    if (_controlStyle != kVKPlayerControlStyleNone) {
                        _controlStyle = kVKPlayerControlStyleEmbedded;
                        _viewBarEmbedded.alpha = 0.0;
                        _viewControlPanelEmbedded.alpha = 0.0;
                        _panelIsHidden = YES;
                        [self performSelector:@selector(addUIEmbedded) withObject:nil afterDelay:0.4];
                    }
                });

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.9 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kVKPlayerDidExitFullscreenNotification object:self userInfo:nil];
                });
            }
        }
    }
}

#pragma mark - gesture recognizer callback

- (void)handleTap:(UITapGestureRecognizer *) sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (sender == _singleTapGestureRecognizer) {
            [self showControlPanel:_panelIsHidden willExpire:YES];
        } else if (sender == _doubleTapGestureRecognizer){
            [self performSelector:@selector(zoomInOut:) withObject:sender];
        }
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self setFullScreen:!_fullScreen animated:YES];
    }
}

#pragma mark - VKDecoder delegate methods

- (void)decoderStateChanged:(VKDecoderState)state errorCode:(VKError)errCode {
    _decoderState = state;
    if (state == kVKDecoderStateConnecting) {
        [self setPanelButtonsEnabled:NO];
         _imgViewAudioOnly.hidden = YES;
        _labelStatusEmbedded.hidden = (_controlStyle == kVKPlayerControlStyleEmbedded) ? NO : YES;
        _readyToApplyPlayingActions = NO;

        _labelBarTitle.text = [self staturBarInitialText];
        _labelStatusEmbedded.text = _labelBarTitle.text;
        _labelBarEmbedded.text = [self barTitle];

        [_activityIndicator startAnimating];
        [_activityIndicatorEmbedded startAnimating];
        [self showControlPanel:YES willExpire:NO];
        _labelElapsedTimeEmbedded.hidden = YES;
        
        _sliderCurrentDuration.value = 0.0;
        _sliderCurrentDurationEmbedded.value = 0.0;
        
        _snapshotReadyToGet = NO;

        VKLog(kVKLogLevelStateChanges, @"Trying to connect to %@", _contentURLString);

    } else if (state == kVKDecoderStateConnected) {
        VKLog(kVKLogLevelStateChanges, @"Connected to the stream server");
    } else if (state == kVKDecoderStateInitialLoading) {
        _readyToApplyPlayingActions = YES;
        VKLog(kVKLogLevelStateChanges, @"Trying to get packets");
    } else if (state == kVKDecoderStateReadyToPlay) {
        VKLog(kVKLogLevelStateChanges, @"Got enough packets to start playing");
        [_activityIndicator stopAnimating];
        [_activityIndicatorEmbedded stopAnimating];

        _labelBarTitle.text = [self barTitle];
        _labelBarEmbedded.text = _labelBarTitle.text;

        [self startElapsedTimer];
        [self setPanelButtonsEnabled:YES];
    } else if (state == kVKDecoderStateBuffering) {
        VKLog(kVKLogLevelStateChanges, @"Buffering now...");
    } else if (state == kVKDecoderStatePlaying) {
        _labelBarTitle.text = [self barTitle];
        _labelBarEmbedded.text = _labelBarTitle.text;
        VKLog(kVKLogLevelStateChanges, @"Playing now...");
        [_buttonPanelPP setImage:[UIImage imageNamed:@"VKImages.bundle/vk-panel-button-pause.png"] forState:UIControlStateNormal];
        [_buttonPanelPPEmbedded setImage:[UIImage imageNamed:@"VKImages.bundle/vk-panel-button-pause-embedded.png"] forState:UIControlStateNormal];
        _labelStatusEmbedded.text = @"";
        _labelStatusEmbedded.hidden = YES;
        _labelElapsedTimeEmbedded.hidden = NO;
        [self showControlPanel:YES willExpire:YES];
        _snapshotReadyToGet = YES;
    } else if (state == kVKDecoderStatePaused) {
        VKLog(kVKLogLevelStateChanges, @"Paused now...");
        [_buttonPanelPP setImage:[UIImage imageNamed:@"VKImages.bundle/vk-panel-button-play.png"] forState:UIControlStateNormal];
        [_buttonPanelPPEmbedded setImage:[UIImage imageNamed:@"VKImages.bundle/vk-panel-button-play-embedded.png"] forState:UIControlStateNormal];
    } else if (state == kVKDecoderStateGotStreamDuration) {
        if (errCode == kVKErrorNone) {
            _durationTotal = [_decodeManager durationInSeconds];
            VKLog(kVKLogLevelDecoder, @"Got stream duration: %f seconds", _durationTotal);
            _sliderCurrentDuration.maximumValue = _durationTotal;
            _sliderCurrentDurationEmbedded.maximumValue = _sliderCurrentDuration.maximumValue;
            _labelStreamTotalDuration.text = [NSString stringWithFormat:@"%02d:%02d", (int)_durationTotal/60, ((int)_durationTotal % 60)];
            _labelStreamTotalDurationEmbedded.text = _labelStreamTotalDuration.text;

            if (_initialPlaybackTime > 0.0 && _initialPlaybackTime < _durationTotal) {
                _durationCurrent = _initialPlaybackTime;
            }
            [self startDurationTimer];
        } else {
            VKLog(kVKLogLevelDecoder, @"Stream duration error -> %@", errorText(errCode));
        }
        [self updateBarWithDurationState:errCode];
    } else if (state == kVKDecoderStateGotAudioStreamInfo) {
        if (errCode != kVKErrorNone) {
            VKLog(kVKLogLevelStateChanges, @"Got audio stream error -> %@", errorText(errCode));
        }
    } else if (state == kVKDecoderStateGotVideoStreamInfo) {
        if (errCode != kVKErrorNone) {
            _imgViewAudioOnly.hidden = NO;
            VKLog(kVKLogLevelStateChanges, @"Got video stream error -> %@", errorText(errCode));
        }
    } else if (state == kVKDecoderStateConnectionFailed) {
        if (_controlStyle == kVKPlayerControlStyleFullScreen) {
            NSString *title = TR(@"Error: Stream can not be opened");
            NSString *body = errorText(errCode);
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title message:body delegate:nil cancelButtonTitle:TR(@"OK") otherButtonTitles:nil] autorelease];
            [alert show];
        }
        
        _readyToApplyPlayingActions = NO;
        _labelBarTitle.text = TR(@"Connection error");
        _labelStatusEmbedded.text = _labelBarTitle.text;
        _labelStatusEmbedded.hidden = (_controlStyle == kVKPlayerControlStyleEmbedded) ? NO : YES;

        [self stopElapsedTimer];
        [self stopDurationTimer];

        [_activityIndicator stopAnimating];
        [_activityIndicatorEmbedded stopAnimating];

        [self updateBarWithDurationState:kVKErrorOpenStream];
        VKLog(kVKLogLevelStateChanges, @"Connection error - %@",errorText(errCode));
    } else if (state == kVKDecoderStateStoppedByUser) {
        _readyToApplyPlayingActions = NO;
        [self stopElapsedTimer];
        [self stopDurationTimer];
        [self updateBarWithDurationState:kVKErrorStreamReadError];
        _labelBarEmbedded.text = @"";
        _labelStatusEmbedded.text = @"";

        [_activityIndicator stopAnimating];
        [_activityIndicatorEmbedded stopAnimating];

        VKLog(kVKLogLevelStateChanges, @"Stopped now...");
    } else if (state == kVKDecoderStateStoppedWithError) {
        _readyToApplyPlayingActions = NO;
        if (errCode == kVKErrorStreamReadError) {
            if (_controlStyle == kVKPlayerControlStyleFullScreen) {
                NSString *title = TR(@"Error: Read error");
                NSString *body = errorText(errCode);
                UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title message:body delegate:nil cancelButtonTitle:TR(@"OK") otherButtonTitles:nil] autorelease];
                [alert show];
            }
            _labelBarTitle.text = TR(@"Error: Read error");
            _labelStatusEmbedded.text = _labelBarTitle.text;
            _labelStatusEmbedded.hidden = (_controlStyle == kVKPlayerControlStyleEmbedded) ? NO : YES;

            VKLog(kVKLogLevelStateChanges, @"Player closed - %@",errorText(errCode));
        } else if (errCode == kVKErrorStreamEOFError) {
            VKLog(kVKLogLevelStateChanges, @"%@, stopped now...", errorText(errCode));
        }
        [self stopElapsedTimer];
        [self stopDurationTimer];

        [_activityIndicator stopAnimating];
        [_activityIndicatorEmbedded stopAnimating];
        
        [self updateBarWithDurationState:errCode];
    }
    if(_delegate && [_delegate respondsToSelector:@selector(player:didChangeState:errorCode:)]) {
        [_delegate player:self didChangeState:state errorCode:errCode];
    }
}

#ifdef VK_RECORDING_CAPABILITY
#pragma mark - VKRecorder delegate methods

- (void)didStartRecordingWithPath:(NSString *)recordPath {
    
    if (_recordingEnabled) {
        [_buttonPanelRecord setImage:[UIImage imageNamed:@"VKImages.bundle/vk-panel-button-record-stop.png"] forState:UIControlStateNormal];
        
        CABasicAnimation *theAnimation;
        theAnimation=[CABasicAnimation animationWithKeyPath:@"opacity"];
        theAnimation.duration=0.5;
        theAnimation.repeatCount=HUGE_VALF;
        theAnimation.autoreverses=YES;
        theAnimation.fromValue=[NSNumber numberWithFloat:1.0];
        theAnimation.toValue=[NSNumber numberWithFloat:0.0];
        [[_buttonPanelRecord layer] addAnimation:theAnimation forKey:@"blink"];
        
        if(_delegate && [_delegate respondsToSelector:@selector(player:didStartRecordingWithPath:)]) {
            [_delegate player:self didStartRecordingWithPath:recordPath];
        }
    }
}

- (void)didStopRecordingWithPath:(NSString *)recordPath error:(VKErrorRecorder)error {
    
    if (_recordingEnabled) {
        
        [[_buttonPanelRecord layer] removeAnimationForKey:@"blink"];
        
        [_buttonPanelRecord setImage:[UIImage imageNamed:@"VKImages.bundle/vk-panel-button-record.png"] forState:UIControlStateNormal];
        
        if(_delegate && [_delegate respondsToSelector:@selector(player:didStopRecordingWithPath:error:)]) {
            [_delegate player:self didStopRecordingWithPath:recordPath error:error];
        }
    }
}
#endif

#pragma mark - External Screen Management (Cable & Airplay)

- (void)screenDidChange:(NSNotification *)notification {
    [self screenDidChange:notification forceDeattached:NO];
}

- (void)screenDidChange:(NSNotification *)notification forceDeattached:(BOOL)deattach {
    
    if (!_allowsAirPlay)
        return;

    NSArray	*screens = [UIScreen screens];
    NSUInteger screenCount = [screens count];
    
	if (screenCount > 1 && !deattach) {
        if (!_mainScreenIsMobile) return;
        
        [self.scrollView setZoomScale:1.0 animated:NO];

        // Select first external screen
		self.extScreen = [screens objectAtIndex:1]; //index 0 is your iPhone/iPad
		NSArray	*availableModes = [self.extScreen availableModes];

        NSInteger selectedRow = [availableModes count] - 1;
        self.extScreen.currentMode = [availableModes objectAtIndex:selectedRow];

        // Set a proper overscanCompensation mode
        self.extScreen.overscanCompensation = UIScreenOverscanCompensationInsetApplicationFrame;

        if (self.extWindow == nil) {
            // Create a new window object (UIWindow) to display your content.
            UIWindow *extWindow = [[[UIWindow alloc] initWithFrame:[self.extScreen bounds]] autorelease];
            self.extWindow = extWindow;
        }

        // Assign the screen object to the screen property of your new window.
        self.extWindow.screen = self.extScreen;

        // Configure the window (by adding views or setting up your OpenGL ES rendering view).
        if ([_renderView superview]) {
            [self removeScreenControlGesturesFromContainerView:_scrollView renderView:_renderView];
            [_renderView removeFromSuperview];
            [self addScreenControlGesturesToContainerView:self.view renderView:NULL];
            _imgViewExternalScreen.hidden = NO;
        }

        // Resize the GL view to fit the external screen
        _scrollView.scrollEnabled = NO;
        _scrollView.disableCenterViewNow = YES;
        _renderView.frame = [_renderView exactFrameRectForSize:self.extWindow.bounds.size fillScreen:[self fillScreen]];
        [_renderView enableRetina:YES];
        [_renderView updateOpenGLFrameSizes];
        // Add the GL view
        [self.extWindow addSubview:_renderView];

        // Show the window.
        self.extWindow.hidden = NO;
        _mainScreenIsMobile = NO;

	} else {

        if (_mainScreenIsMobile) return;
        
        // Configure the main window (by adding views or setting up your OpenGL ES rendering view).
        _imgViewExternalScreen.hidden = YES;
        [self removeScreenControlGesturesFromContainerView:self.view renderView:NULL];
        [_renderView removeFromSuperview];
        [self addScreenControlGesturesToContainerView:_scrollView renderView:_renderView];

        // Resize the GL view to fit the iPhone/iPad screen
        _renderView.frame = [_renderView exactFrameRectForSize:self.view.bounds.size fillScreen:[self fillScreen]];
        [_renderView enableRetina:YES];
        _scrollView.disableCenterViewNow = NO;

        // Display the GL view on the iPhone/iPad screen
        _scrollView.scrollEnabled = YES;
        [self.scrollView insertSubview:_renderView atIndex:0];
        
        [self.scrollView setZoomScale:1.0 animated:NO];

        [_renderView performSelector:@selector(updateOpenGLFrameSizes) withObject:nil afterDelay:2.0];
        _mainScreenIsMobile = YES;
        
        // Release external screen and window
        self.extWindow.hidden = YES;
        self.extWindow = nil;
	}
}


#pragma mark - Memory events & deallocation

- (void)dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_imgSliderMin release];
    [_imgSliderMax release];
    [_imgSliderThumb release];

    [_timerInfoViewUpdate release];
    [_viewInfo release];

    [_labelStatusEmbedded release];
    [_viewControlPanel release];
    [_toolBar release];
    [_viewControlPanelEmbedded release];
    [_viewBarEmbedded release];
    [_imgViewAudioOnly release];
    [_imgViewExternalScreen release];
    
    [_closeInfoViewGestureRecognizer release];
    [_longGestureRecognizer release];
    
    [super dealloc];
}

@end

