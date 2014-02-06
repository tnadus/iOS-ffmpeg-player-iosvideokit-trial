//
//  VKPlayerViewController.m
//  VideoKit
//
//  Created by Tarum Nadus on 11/16/12.
//  Copyright (c) 2013-2014 VideoKit. All rights reserved.
//

#import "VKPlayerController.h"
#import <QuartzCore/QuartzCore.h>

@interface VKFullscreenContainer : UIViewController {
    VKPlayerController *_playerController;
    UIView *_superviewBefore;
    CGRect _rectBefore;
    UIViewAutoresizing _autoresizingMaskBefore;
}

- (id)initWithPlayerController:(VKPlayerController *)player;
- (void)onDismissWithAnimated:(BOOL)animated;

@end

@implementation VKFullscreenContainer

- (id)initWithPlayerController:(VKPlayerController *)player {
    self = [super init];
    if (self) {
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        _playerController = [player retain];
        _rectBefore = [player.view frame];
        _superviewBefore = [[player.view superview] retain];
        _autoresizingMaskBefore = [player.view autoresizingMask];
    }
    return self;
}

#pragma mark - View Life Cycle

- (void) loadView {
    CGRect bounds = [[UIScreen mainScreen] applicationFrame];

    if (UIInterfaceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
        bounds =  CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.height, bounds.size.width);
    }
    self.view = [[[UIView alloc] initWithFrame:bounds] autorelease];
    self.view.backgroundColor = [_playerController backgroundColor];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _playerController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _playerController.view.frame = self.view.bounds;
    [self.view addSubview:_playerController.view];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

#pragma mark - Private Methods

- (void)onDismissWithAnimated:(BOOL)animated {
    float duration = (animated) ? 0.5 : 0.0;
    [UIView animateWithDuration:duration animations:^{
        _playerController.view.autoresizingMask = _autoresizingMaskBefore;
        _playerController.view.frame = _rectBefore;
    } completion:^(BOOL finished) {
        [self dismissViewControllerAnimated:NO completion:^{
            [_playerController.view removeFromSuperview];
            [_superviewBefore addSubview:_playerController.view];
        }];
    }];
}

#pragma mark - Orientation

- (NSUInteger) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)dealloc {
    [_superviewBefore release];
    [_playerController release];
    [super dealloc];
}

@end


#pragma mark - VKPlayerController


#import "VKGLES2View.h"
#import "VKStreamInfoView.h"

#import <MediaPlayer/MediaPlayer.h>

/* VKPlayer Fullscreen mode changed notifications */
NSString *kVKPlayerWillEnterFullscreenNotification = @"VKPlayerWillEnterFullscreenNotification";
NSString *kVKPlayerDidEnterFullscreenNotification = @"VKPlayerDidEnterFullscreenNotification";
NSString *kVKPlayerWillExitFullscreenNotification = @"VKPlayerWillExitFullscreenNotification";
NSString *kVKPlayerDidExitFullscreenNotification = @"VKPlayerDidExitFullscreenNotification";

#define BAR_BUTTON_TAG_DONE             1000
#define BAR_BUTTON_TAG_SCALE            1001

#define PANEL_BUTTON_TAG_PP_TOGGLE      2001
#define PANEL_BUTTON_TAG_INFO           2002
#define PANEL_BUTTON_TAG_FULLSCREEN     2003

static NSString * errorText(VKError errCode);

@interface VKPlayerController ()<VKDecoderDelegate, AVAudioSessionDelegate> {

    MPVolumeView *_sliderVolume;
    
    //UI elements & controls for fullscreen
    UIActivityIndicatorView *_activityIndicator;
    UILabel *_labelBarTitle;
    UIToolbar *_toolBar;
    UIBarButtonItem *_barButtonDone;
    UIBarButtonItem *_barButtonSpaceLeft;
    UIBarButtonItem *_barButtonContainer;
    UIBarButtonItem *_barButtonSpaceRight;
    UIBarButtonItem *_barButtonScale;
    UIView *_viewCenteredOnBar;

    UIView *_viewControlPanel;
    UIImageView *_imgViewControlPanel;
    UILabel *_labelElapsedTime;
    UIButton *_buttonPanelPP;
    UIButton *_buttonPanelInfo;
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
    UIButton *_buttonScaleEmbedded;

    UILabel *_labelStatusEmbedded;

    //UI elements other
    UIImage *_imgSliderMin;
    UIImage *_imgSliderMax;
    UIImage *_imgSliderThumb;
    
    UIImageView *_imgViewAudioOnly;
    UIImageView *_imgViewExternalScreen;

    //UI elements
    VKStreamInfoView *_viewInfo;

    UIView *_view;
    VKGLES2View *_renderView;

    NSString *_barTitle;
    BOOL _statusBarHidden;
    BOOL _statusBarHiddenBefore;
    BOOL _sliderDurationCurrentTouched;

    //Gesture recognizers
    UITapGestureRecognizer *_doubleTapGestureRecognizer;
    UITapGestureRecognizer *_singleTapGestureRecognizer;
    UIPinchGestureRecognizer *_pinchGestureRecognizer;

    UITapGestureRecognizer *_closeInfoViewGestureRecognizer;

    //Timers & timer controls
    BOOL _panelIsHidden;
    NSTimer *_timerPanelHidden;

    NSTimer *_timerElapsedTime;
    int _elapsedTime;

    NSTimer *_timerInfoViewUpdate;

    NSTimer *_timerDuration;
    float _durationCurrent;
    float _durationTotal;

    //Container & screens
    UIViewController *_containerVc;
    BOOL _mainScreenIsMobile;
    BOOL _allowsAirPlay;

    //stream related
    NSString *_contentURLString;
    VKAVDecodeManager *_decodeManager;
    NSDictionary *_decodeOptions;
    VKDecoderState _decoderState;

    //for controlling play/stop actions
    dispatch_queue_t _playStopQueue;
    BOOL _playingIsInProgress;
    BOOL _stoppingIsInPlaying;
    
    //snapshot
    BOOL _snapshotReadyToGet;
}

@property (nonatomic, retain) UIWindow *extWindow;
@property (nonatomic, retain) UIScreen *extScreen;

- (IBAction)onBarButtonsTapped:(id)sender;
- (IBAction)onControlPanelButtonsTapped:(id)sender;

@end

@implementation VKPlayerController

@synthesize barTitle = _barTitle;
@synthesize statusBarHidden = _statusBarHidden;
@synthesize containerVc = _containerVc;
@synthesize decoderState = _decoderState;
@synthesize contentURLString = _contentURLString;
@synthesize decoderOptions = _decodeOptions;
@synthesize fullScreen = _fullScreen;
@synthesize controlStyle = _controlStyle;
@synthesize initialPlaybackTime = _initialPlaybackTime;
@synthesize loopPlayback = _loopPlayback;
@synthesize autoStopAtEnd = _autoStopAtEnd;
@synthesize allowsAirPlay = _allowsAirPlay;
@synthesize delegate = _delegate;
@synthesize renderView = _renderView;
@synthesize backgroundColor = _backgroundColor;

#pragma mark Initialization

- (id)init {
    self = [super init];
    if (self) {
        // Custom initialization
        _panelIsHidden = NO;
        _statusBarHidden = NO;
        _statusBarHiddenBefore = NO;

        _fullScreen = NO;
        _controlStyle = kVKPlayerControlStyleEmbedded;
        _initialPlaybackTime = 0.0;
        _loopPlayback = 1;
        _allowsAirPlay = NO;

        _playingIsInProgress = NO;
        _stoppingIsInPlaying = NO;
        _playStopQueue = dispatch_queue_create("play_stop_lock", NULL);
        
        _snapshotReadyToGet = NO;

        [self createUI];

        return self;
    }
    return nil;
}

- (id)initWithURLString:(NSString *)urlString {

    self = [self init];
    if (self) {
        // Custom initialization
        [self setContentURLString:urlString];
        return self;
    }
    return nil;
}

- (void)setContentURLString:(NSString *)urlString {
    _decoderState = kVKDecoderStateNone;
    if(!urlString) urlString = @"http://url.is.null";
    
    if (_contentURLString) {
        [_contentURLString release];
        _contentURLString = nil;
    }
    _contentURLString = [urlString retain];
    _barTitle = [[urlString lastPathComponent] retain];
}

#pragma mark Subviews management

- (void)createUI
{
    _backgroundColor = [[UIColor blackColor] retain];
    
    CGRect bounds = [[UIScreen mainScreen] applicationFrame];

    if (UIInterfaceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
        bounds =  CGRectMake( 0.0f, 0.0f, bounds.size.height, bounds.size.width);
    } else {
        bounds =  CGRectMake( 0.0f, 0.0f, bounds.size.width, bounds.size.height);
    }

    _view = [[UIView alloc] initWithFrame:bounds];
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
    float viewWidth = self.view.bounds.size.width;
    _toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, viewWidth, 44.0)];
    _toolBar.autoresizesSubviews = YES;
    _toolBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    _toolBar.barStyle = UIBarStyleBlackTranslucent;

    NSMutableArray *toolBarItems = [NSMutableArray array];

    /* Toolbar on top: _barButtonDone */
    _barButtonDone = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onBarButtonsTapped:)] autorelease];
    _barButtonDone.style = UIBarButtonItemStylePlain;
    _barButtonDone.tag = BAR_BUTTON_TAG_DONE;
    [toolBarItems addObject:_barButtonDone];

    /* Toolbar on top: _barButtonSpaceLeft */
    _barButtonSpaceLeft = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
    [toolBarItems addObject:_barButtonSpaceLeft];

    /* Toolbar on top: _viewCenteredOnBar */
    _viewCenteredOnBar = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 6.0, viewWidth - 100, 33.0)] autorelease];
    _viewCenteredOnBar.autoresizesSubviews = YES;
    _viewCenteredOnBar.autoresizingMask =  UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    _viewCenteredOnBar.backgroundColor = [UIColor clearColor];

    float heightSubviewOnBar = 21.0;
    /* Toolbar on top: _labelBarTitle */
    _labelBarTitle = [[[UILabel alloc] initWithFrame:CGRectMake(0.0, 6.0, _viewCenteredOnBar.frame.size.width, heightSubviewOnBar)] autorelease];
    _labelBarTitle.autoresizesSubviews = YES;
    _labelBarTitle.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    _labelBarTitle.contentMode = UIViewContentModeCenter;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending) {
        //running on iOS 6.0 or higher
        _labelBarTitle.lineBreakMode = NSLineBreakByTruncatingTail;
        _labelBarTitle.minimumScaleFactor = 0.3;
        _labelBarTitle.textAlignment = NSTextAlignmentCenter;
    } else {
        //running on iOS 5.x
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
        _labelBarTitle.lineBreakMode = UILineBreakModeTailTruncation;
        _labelBarTitle.minimumFontSize = 10.0;
        _labelBarTitle.textAlignment = UITextAlignmentCenter;
#endif
    }
#else
    _labelBarTitle.lineBreakMode = UILineBreakModeTailTruncation;
    _labelBarTitle.minimumFontSize = 10.0;
    _labelBarTitle.textAlignment = UITextAlignmentCenter;
#endif

    _labelBarTitle.contentMode = UIViewContentModeLeft;
    _labelBarTitle.numberOfLines = 1;
    _labelBarTitle.opaque = YES;
    _labelBarTitle.backgroundColor = [UIColor clearColor];
    _labelBarTitle.shadowOffset = CGSizeMake(0.0, -1.0);
    _labelBarTitle.textColor = [UIColor colorWithRed:0.906 green:0.906 blue:0.906 alpha:1.000];
    _labelBarTitle.font = [UIFont fontWithName:@"HelveticaNeue" size:18];
    _labelBarTitle.text = _barTitle;
    [_viewCenteredOnBar addSubview:_labelBarTitle];

    /* Toolbar on top: _activityIndicator */
    _activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
    _activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    _activityIndicator.frame = CGRectMake((_viewCenteredOnBar.frame.size.width + 120.0)/2.0, 7.0, 20.0, 20.0);
    _activityIndicator.hidesWhenStopped = YES;
    _activityIndicator.backgroundColor = [UIColor clearColor];
    [_viewCenteredOnBar addSubview:_activityIndicator];

    /* Current & total duration of stream labels */
    float wStrmTimeLabelsOnBar = 40.0;
    float marginX = 8.0;
    _labelStreamCurrentTime = [[[UILabel alloc] initWithFrame:CGRectMake(marginX, 6.0, wStrmTimeLabelsOnBar, heightSubviewOnBar)] autorelease];
    _labelStreamCurrentTime.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending) {
        //running on iOS 6.0 or higher
        _labelStreamCurrentTime.textAlignment = NSTextAlignmentCenter;
    } else {
        //running on iOS 5.x
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
        _labelStreamCurrentTime.textAlignment = UITextAlignmentCenter;
#endif
    }
#else
    _labelStreamCurrentTime.textAlignment = UITextAlignmentCenter;
#endif
    _labelStreamCurrentTime.text = @"00:00";
    _labelStreamCurrentTime.numberOfLines = 1;
    _labelStreamCurrentTime.opaque = NO;
    _labelStreamCurrentTime.backgroundColor = [UIColor clearColor];
    _labelStreamCurrentTime.textColor = [UIColor whiteColor];
    _labelStreamCurrentTime.font = [UIFont fontWithName:@"HelveticaNeue" size:13.0];
    _labelStreamCurrentTime.hidden = YES;
    [_viewCenteredOnBar addSubview:_labelStreamCurrentTime];

    /* labelStreamTotalDuration */
    _labelStreamTotalDuration = [[[UILabel alloc] initWithFrame:CGRectMake(_viewCenteredOnBar.frame.size.width - wStrmTimeLabelsOnBar - marginX, 6.0, wStrmTimeLabelsOnBar, heightSubviewOnBar)] autorelease];
    _labelStreamTotalDuration.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending) {
        //running on iOS 6.0 or higher
        _labelStreamTotalDuration.textAlignment = NSTextAlignmentCenter;
    } else {
        //running on iOS 5.x
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
        _labelStreamTotalDuration.textAlignment = UITextAlignmentCenter;
#endif
    }
#else
    _labelStreamTotalDuration.textAlignment = UITextAlignmentRight;
#endif

    _labelStreamTotalDuration.numberOfLines = 1;
    _labelStreamTotalDuration.opaque = NO;
    _labelStreamTotalDuration.backgroundColor = [UIColor clearColor];
    _labelStreamTotalDuration.textColor = [UIColor whiteColor];
    _labelStreamTotalDuration.font = [UIFont fontWithName:@"HelveticaNeue" size:13.0];
    _labelStreamTotalDuration.hidden = YES;
    [_viewCenteredOnBar addSubview:_labelStreamTotalDuration];

    /* sliderCurrentDuration */
    float widthSlider = _viewCenteredOnBar.frame.size.width - 2*wStrmTimeLabelsOnBar - 4*marginX;
    _sliderCurrentDuration = [[[UISlider alloc] initWithFrame:CGRectMake(_labelStreamCurrentTime.frame.size.width + 2*marginX, 6.0, widthSlider, heightSubviewOnBar)] autorelease];
    _sliderCurrentDuration.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    _sliderCurrentDuration.minimumValue = 0.0;
    _sliderCurrentDuration.value = 0.0;
    _sliderCurrentDuration.continuous = YES;
    [_sliderCurrentDuration addTarget:self action:@selector(onSliderCurrentDurationTouched:) forControlEvents:UIControlEventTouchDown];
    [_sliderCurrentDuration addTarget:self action:@selector(onSliderCurrentDurationTouchedOut:) forControlEvents:UIControlEventTouchUpInside];
    [_sliderCurrentDuration addTarget:self action:@selector(onSliderCurrentDurationTouchedOut:) forControlEvents:UIControlEventTouchUpOutside];
    [_sliderCurrentDuration addTarget:self action:@selector(onSliderCurrentDurationChanged:) forControlEvents:UIControlEventValueChanged];
    _sliderCurrentDuration.hidden = YES;
    [_sliderCurrentDuration setMinimumTrackImage:_imgSliderMin forState:UIControlStateNormal];
    [_sliderCurrentDuration setMaximumTrackImage:_imgSliderMax forState:UIControlStateNormal];
    [_sliderCurrentDuration setThumbImage:_imgSliderThumb forState:UIControlStateNormal];
    [_viewCenteredOnBar addSubview:_sliderCurrentDuration];

    /* Toolbar on top: _barButtonContainer */
    _barButtonContainer = [[[UIBarButtonItem alloc] initWithCustomView:_viewCenteredOnBar] autorelease];
    [toolBarItems addObject:_barButtonContainer];

    /* Toolbar on top: _barButtonSpaceRight */
    _barButtonSpaceRight = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:NULL action:NULL] autorelease];
    [toolBarItems addObject:_barButtonSpaceRight];

    /* Toolbar on top: _barButtonScale */
    _barButtonScale = [[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStyleBordered target:self action:@selector(onBarButtonsTapped:)] autorelease];
    _barButtonScale.tag = BAR_BUTTON_TAG_SCALE;
    [toolBarItems addObject:_barButtonScale];

    [_toolBar setItems:toolBarItems];

    /* set the images */
    [_barButtonScale setImage:[UIImage imageNamed:@"VKImages.bundle/vk-bar-button-zoom-out.png"]];
}

- (void)createUIFullScreenPanel {
    /* Control panel: _viewControlPanel */
    int mrgnBtPanel = 8.0;
    int hPanel = 93.0;
    int wPanel = 314.0;
    int yPanel = self.view.bounds.size.height - hPanel - mrgnBtPanel;
    int xPanel = (self.view.bounds.size.width - wPanel)/2.0;

    _viewControlPanel = [[UIView alloc] initWithFrame:CGRectMake(xPanel, yPanel, wPanel, hPanel)];
    _viewControlPanel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin |
    UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    _viewControlPanel.contentMode = UIViewContentModeCenter;
    _viewControlPanel.backgroundColor = [UIColor clearColor];

    /* Control panel: _imgViewControlPanel */
    _imgViewControlPanel = [[[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 314.0, 93.0)] autorelease];
    _imgViewControlPanel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    _imgViewControlPanel.contentMode = UIViewContentModeCenter;
    _imgViewControlPanel.backgroundColor = [UIColor clearColor];
    [_viewControlPanel addSubview:_imgViewControlPanel];

    /* Control panel: _buttonPanelPP */
    _buttonPanelPP = [[[UIButton alloc] initWithFrame:CGRectMake(142.0, 13.0, 30.0, 27.0)] autorelease];
    _buttonPanelPP.showsTouchWhenHighlighted = YES;
    _buttonPanelPP.tag = PANEL_BUTTON_TAG_PP_TOGGLE;
    [_buttonPanelPP addTarget:self action:@selector(onControlPanelButtonsTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_viewControlPanel addSubview:_buttonPanelPP];

    /* Control panel: _buttonPanelInfo */
    _buttonPanelInfo = [[[UIButton alloc] initWithFrame:CGRectMake(246.0, 11.0, 30.0, 30.0)] autorelease];
    _buttonPanelInfo.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    _buttonPanelInfo.showsTouchWhenHighlighted = YES;
    _buttonPanelInfo.contentMode = UIViewContentModeCenter;
    _buttonPanelInfo.tag = PANEL_BUTTON_TAG_INFO;
    [_buttonPanelInfo addTarget:self action:@selector(onControlPanelButtonsTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_viewControlPanel addSubview:_buttonPanelInfo];

    /* Control panel: _imgViewSpeaker */
    _imgViewSpeaker = [[[UIImageView alloc] initWithFrame:CGRectMake(20.0, 50.0, 21.0, 23.0)] autorelease];
    _imgViewSpeaker.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    [_viewControlPanel addSubview:_imgViewSpeaker];

    /* Control panel: _labelElapsedTime */
    _labelElapsedTime = [[[UILabel alloc] initWithFrame:CGRectMake(20.0, 16.0, 64.0, 21.0)] autorelease];
    _labelElapsedTime.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    _labelElapsedTime.contentMode = UIViewContentModeLeft;
    _labelElapsedTime.text = @"00:00";
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending) {
        //running on iOS 6.0 or higher
        _labelElapsedTime.textAlignment = NSTextAlignmentLeft;
    } else {
        //running on iOS 5.x
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
        _labelElapsedTime.textAlignment = UITextAlignmentLeft;
#endif
    }
#else
    _labelElapsedTime.textAlignment = UITextAlignmentLeft;
#endif
    _labelElapsedTime.backgroundColor = [UIColor clearColor];
    _labelElapsedTime.opaque = NO;
    _labelElapsedTime.textColor = [UIColor colorWithRed:0.906 green:0.906 blue:0.906 alpha:1.000];
    _labelElapsedTime.font = [UIFont fontWithName:@"HelveticaNeue" size:16];
    [_viewControlPanel addSubview:_labelElapsedTime];

    /* Control panel: _sliderVolume */
    _sliderVolume = [[[MPVolumeView alloc] initWithFrame:CGRectMake(53.0, 51.0, 219.0, 23.0)] autorelease];
    _sliderVolume.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_viewControlPanel addSubview:_sliderVolume];

    /* set the images */
    _imgViewControlPanel.image = [UIImage imageNamed:@"VKImages.bundle/vk-panel-bg.png"];
    _imgViewSpeaker.image = [UIImage imageNamed:@"VKImages.bundle/vk-panel-button-speaker.png"];
    [_buttonPanelPP setImage:[UIImage imageNamed:@"VKImages.bundle/vk-panel-button-play.png"] forState:UIControlStateNormal];
    [_buttonPanelInfo setImage:[UIImage imageNamed:@"VKImages.bundle/vk-panel-button-info.png"] forState:UIControlStateNormal];
}

- (void)createUIEmbedded {
    [self createUIEmbeddedBar];
    [self createUIEmbeddedPanel];

    int hLabel = 30.0;
    int wLabel = 120.0;
    int yLabel = (self.view.bounds.size.height - hLabel)/2.0;
    int xLabel = (self.view.bounds.size.width - wLabel)/2.0;

    _labelStatusEmbedded = [[UILabel alloc] initWithFrame:CGRectMake(xLabel, yLabel, wLabel, hLabel)];
    _labelStatusEmbedded.autoresizingMask =  UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin| UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    _labelStatusEmbedded.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
    _labelStatusEmbedded.backgroundColor = [UIColor clearColor];
    _labelStatusEmbedded.textColor = [UIColor whiteColor];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending) {
        //running on iOS 6.0 or higher
        _labelStatusEmbedded.lineBreakMode = NSLineBreakByTruncatingTail;
        _labelStatusEmbedded.minimumScaleFactor = 0.5;
        _labelStatusEmbedded.textAlignment = NSTextAlignmentCenter;
    } else {
        //running on iOS 5.x
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
        _labelStatusEmbedded.lineBreakMode = UILineBreakModeTailTruncation;
        _labelStatusEmbedded.minimumFontSize = 8.0;
        _labelStatusEmbedded.textAlignment = UITextAlignmentCenter;
#endif
    }
#else
    _labelStatusEmbedded.lineBreakMode = UILineBreakModeTailTruncation;
    _labelStatusEmbedded.minimumFontSize = 10.0;
    _labelStatusEmbedded.textAlignment = UITextAlignmentCenter;
#endif
}

- (void)createUIEmbeddedBar {
    float viewWidth = self.view.bounds.size.width;
    _viewBarEmbedded = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, viewWidth, 30.0)];
    _viewBarEmbedded.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin |
    UIViewAutoresizingFlexibleWidth;
    _viewBarEmbedded.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.32];

    _labelBarEmbedded = [[[UILabel alloc] initWithFrame:CGRectMake(8.0, 0.0, viewWidth, 30.0)] autorelease];
    _labelBarEmbedded.autoresizingMask =  UIViewAutoresizingFlexibleRightMargin |  UIViewAutoresizingFlexibleBottomMargin |  UIViewAutoresizingFlexibleWidth;
    _labelBarEmbedded.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
    _labelBarEmbedded.backgroundColor = [UIColor clearColor];
    _labelBarEmbedded.textColor = [UIColor whiteColor];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending) {
        //running on iOS 6.0 or higher
        _labelBarEmbedded.lineBreakMode = NSLineBreakByTruncatingTail;
        _labelBarEmbedded.minimumScaleFactor = 0.5;
    } else {
        //running on iOS 5.x
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
        _labelBarEmbedded.lineBreakMode = UILineBreakModeTailTruncation;
        _labelBarEmbedded.minimumFontSize = 8.0;
#endif
    }
#else
    _labelBarEmbedded.lineBreakMode = UILineBreakModeTailTruncation;
    _labelBarEmbedded.minimumFontSize = 10.0;
#endif
    [_viewBarEmbedded addSubview:_labelBarEmbedded];

    float activityWidth = 20.0;
    float marginX = 8.0;
    _activityIndicatorEmbedded = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
    _activityIndicatorEmbedded.frame = CGRectMake(viewWidth - (activityWidth + marginX), 5.0, activityWidth, activityWidth);
    _activityIndicatorEmbedded.hidesWhenStopped = YES;
    _activityIndicatorEmbedded.autoresizingMask =  UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    [_viewBarEmbedded addSubview:_activityIndicatorEmbedded];

    float labelElapsedWidth = 35.0;
    _labelElapsedTimeEmbedded = [[[UILabel alloc] initWithFrame:CGRectMake(viewWidth - (labelElapsedWidth  + marginX), 3.0, labelElapsedWidth, 23.0)] autorelease];
    _labelElapsedTimeEmbedded.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    _labelElapsedTimeEmbedded.text = @"00:00";
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending) {
        //running on iOS 6.0 or higher
        _labelElapsedTimeEmbedded.textAlignment = NSTextAlignmentCenter;
    } else {
        //running on iOS 5.x
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
        _labelElapsedTimeEmbedded.textAlignment = UITextAlignmentCenter;
#endif
    }
#else
    _labelElapsedTimeEmbedded.textAlignment = UITextAlignmentCenter;
#endif
    _labelElapsedTimeEmbedded.backgroundColor = [UIColor clearColor];
    _labelElapsedTimeEmbedded.textColor = [UIColor whiteColor];
    _labelElapsedTimeEmbedded.font = [UIFont fontWithName:@"HelveticaNeue" size:13];
    [_viewBarEmbedded addSubview:_labelElapsedTimeEmbedded];
}

- (void)createUIEmbeddedPanel {
    float viewWidth = self.view.bounds.size.width;
    float marginX = 8.0;
    float marginY = 3.0;

    float viewPanelHeight = 30.0;
    float viewPanelEmbeddedOriginY = self.view.bounds.size.height - viewPanelHeight;
    _viewControlPanelEmbedded = [[UIView alloc] initWithFrame:CGRectMake(0.0, viewPanelEmbeddedOriginY, viewWidth, viewPanelHeight)];
    _viewControlPanelEmbedded.autoresizingMask =  UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    _viewControlPanelEmbedded.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.32];

    float buttonWidth = 24.0;
    _buttonPanelPPEmbedded = [[[UIButton alloc] initWithFrame:CGRectMake(marginX, marginY, buttonWidth, buttonWidth)] autorelease];
    _buttonPanelPPEmbedded.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    _buttonPanelPPEmbedded.showsTouchWhenHighlighted = YES;
    _buttonPanelPPEmbedded.tag = PANEL_BUTTON_TAG_PP_TOGGLE;
    _buttonPanelPPEmbedded.contentMode = UIViewContentModeCenter;
    [_buttonPanelPPEmbedded addTarget:self action:@selector(onControlPanelButtonsTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_viewControlPanelEmbedded addSubview:_buttonPanelPPEmbedded];

    float labelWidth = 35.0;
    float labelHeight = 23.0;
    _labelStreamCurrentTimeEmbedded = [[[UILabel alloc] initWithFrame:CGRectMake(36.0, marginY, labelWidth, labelHeight)] autorelease];
    _labelStreamCurrentTimeEmbedded.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    _labelStreamCurrentTimeEmbedded.font = [UIFont fontWithName:@"HelveticaNeue" size:13];
    _labelStreamCurrentTimeEmbedded.backgroundColor = [UIColor clearColor];
    _labelStreamCurrentTimeEmbedded.textColor = [UIColor whiteColor];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending) {
        //running on iOS 6.0 or higher
        _labelStreamCurrentTimeEmbedded.textAlignment = NSTextAlignmentCenter;
    } else {
        //running on iOS 5.x
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
        _labelStreamCurrentTimeEmbedded.textAlignment = UITextAlignmentCenter;
#endif
    }
#else
    _labelStreamCurrentTimeEmbedded.textAlignment = UITextAlignmentCenter;
#endif
    [_viewControlPanelEmbedded addSubview:_labelStreamCurrentTimeEmbedded];

    float buttonScaleOriginX = viewWidth - (marginX + buttonWidth);
    _buttonScaleEmbedded = [[[UIButton alloc] initWithFrame:CGRectMake(buttonScaleOriginX, marginY, buttonWidth, buttonWidth)] autorelease];
    _buttonScaleEmbedded.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    _buttonScaleEmbedded.showsTouchWhenHighlighted = YES;
    _buttonScaleEmbedded.tag = PANEL_BUTTON_TAG_FULLSCREEN;
    _buttonScaleEmbedded.contentMode = UIViewContentModeCenter;
    [_buttonScaleEmbedded addTarget:self action:@selector(onControlPanelButtonsTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_viewControlPanelEmbedded addSubview:_buttonScaleEmbedded];

    float labelStreamDurationOriginX = _buttonScaleEmbedded.frame.origin.x - (2.0 + labelWidth);
    _labelStreamTotalDurationEmbedded = [[[UILabel alloc] initWithFrame:CGRectMake(labelStreamDurationOriginX, marginY, labelWidth, labelHeight)] autorelease];
    _labelStreamTotalDurationEmbedded.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    _labelStreamTotalDurationEmbedded.font = [UIFont fontWithName:@"HelveticaNeue" size:13];
    _labelStreamTotalDurationEmbedded.backgroundColor = [UIColor clearColor];
    _labelStreamTotalDurationEmbedded.textColor = [UIColor whiteColor];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending) {
        //running on iOS 6.0 or higher
        _labelStreamTotalDurationEmbedded.textAlignment = NSTextAlignmentCenter;
    } else {
        //running on iOS 5.x
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
        _labelStreamTotalDurationEmbedded.textAlignment = UITextAlignmentCenter;
#endif
    }
#else
    _labelStreamTotalDurationEmbedded.textAlignment = UITextAlignmentCenter;
#endif
    [_viewControlPanelEmbedded addSubview:_labelStreamTotalDurationEmbedded];

    float sliderOriginX = _labelStreamCurrentTimeEmbedded.frame.origin.x + _labelStreamCurrentTimeEmbedded.frame.size.width + marginX/2.0;
    float sliderWidth = _labelStreamTotalDurationEmbedded.frame.origin.x - (_labelStreamCurrentTimeEmbedded.frame.origin.x + _labelStreamCurrentTimeEmbedded.frame.size.width) - marginX;
    _sliderCurrentDurationEmbedded = [[[UISlider alloc] initWithFrame:CGRectMake(sliderOriginX, marginY, sliderWidth, labelHeight)] autorelease];
    _sliderCurrentDurationEmbedded.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;

    _sliderCurrentDurationEmbedded.minimumValue = 0.0;
    _sliderCurrentDurationEmbedded.value = 0.0;
    _sliderCurrentDurationEmbedded.continuous = YES;
    [_sliderCurrentDurationEmbedded addTarget:self action:@selector(onSliderCurrentDurationTouched:) forControlEvents:UIControlEventTouchDown];
    [_sliderCurrentDurationEmbedded addTarget:self action:@selector(onSliderCurrentDurationTouchedOut:) forControlEvents:UIControlEventTouchUpInside];
    [_sliderCurrentDurationEmbedded addTarget:self action:@selector(onSliderCurrentDurationTouchedOut:) forControlEvents:UIControlEventTouchUpOutside];
    [_sliderCurrentDurationEmbedded addTarget:self action:@selector(onSliderCurrentDurationChanged:) forControlEvents:UIControlEventValueChanged];
    _sliderCurrentDurationEmbedded.hidden = YES;
    [_sliderCurrentDurationEmbedded setMinimumTrackImage:_imgSliderMin forState:UIControlStateNormal];
    [_sliderCurrentDurationEmbedded setMaximumTrackImage:_imgSliderMax forState:UIControlStateNormal];
    [_sliderCurrentDurationEmbedded setThumbImage:_imgSliderThumb forState:UIControlStateNormal];
    [_viewControlPanelEmbedded addSubview:_sliderCurrentDurationEmbedded];

    [_buttonPanelPPEmbedded setImage:[UIImage imageNamed:@"VKImages.bundle/vk-panel-button-play-embedded.png"] forState:UIControlStateNormal];
    [_buttonScaleEmbedded setImage:[UIImage imageNamed:@"VKImages.bundle/vk-bar-button-zoom-out.png"] forState:UIControlStateNormal];
}

- (void)createUICenter {
    /* Center subviews: _imgViewAudioOnly */
    int hAudioOnly = 156.0/2.0;
    int wAudioOnly = 185.0/2.0;
    int yAudioOnly = (self.view.bounds.size.height - hAudioOnly)/2.0;
    int xAudioOnly = (self.view.bounds.size.width - wAudioOnly)/2.0;
    _imgViewAudioOnly = [[UIImageView alloc] initWithFrame:CGRectMake(xAudioOnly, yAudioOnly, wAudioOnly, hAudioOnly)];
    _imgViewAudioOnly.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin| UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    _imgViewAudioOnly.contentMode = UIViewContentModeScaleAspectFit;
    _imgViewAudioOnly.hidden = YES;
    _imgViewAudioOnly.opaque = NO;
    [self.view addSubview:_imgViewAudioOnly];

    /* Center subviews: _imgViewExternalScreen */
    int hExtScreen = 122.0;
    int wExtScreen = 91.0;
    int yExtScreen = (self.view.bounds.size.height - hExtScreen)/2.0;
    int xExtScreen = (self.view.bounds.size.width - wExtScreen)/2.0;
    _imgViewExternalScreen = [[UIImageView alloc] initWithFrame:CGRectMake(xExtScreen, yExtScreen, wExtScreen, hExtScreen)];
    _imgViewExternalScreen.autoresizesSubviews = YES;
    _imgViewExternalScreen.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin| UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    _imgViewExternalScreen.contentMode = UIViewContentModeScaleAspectFit;
    _imgViewExternalScreen.hidden = YES;
    _imgViewExternalScreen.opaque = NO;
    _imgViewExternalScreen.userInteractionEnabled = YES;
    [self.view insertSubview:_imgViewExternalScreen atIndex:0];

    int hViewInfo = 230.0;
    int hViewInfoMargin = 10.0;
    int wViewInfo = 280.0;
    int yViewInfo = (self.view.bounds.size.height - hViewInfo)/2.0 - hViewInfoMargin;
    int xViewInfo = (self.view.bounds.size.width - wViewInfo)/2.0;
    _viewInfo = [[VKStreamInfoView alloc] initWithFrame:CGRectMake(xViewInfo, yViewInfo, wViewInfo, hViewInfo)];
    _viewInfo.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    _viewInfo.contentMode = UIViewContentModeCenter;
    _viewInfo.hidden = YES;
    [self addGesturesToInfoView:_viewInfo];
    [self.view addSubview:_viewInfo];

    /* set the images */
    _imgViewAudioOnly.image = [UIImage imageNamed:@"VKImages.bundle/vk-audio-only.png"];
    _imgViewExternalScreen.image = [UIImage imageNamed:@"VKImages.bundle/vk-external-screen.png"];
}

- (void)addUIFullScreen {
    if (![_viewControlPanel superview])
        [self.view addSubview:_viewControlPanel];

    if (![_toolBar superview])
        [self.view addSubview:_toolBar];
}

- (void)removeUIFullScreen {
    if ([_viewControlPanel superview])
        [_viewControlPanel removeFromSuperview];

    if ([_toolBar superview])
        [_toolBar removeFromSuperview];
}

- (void)addUIEmbedded {
    if (![_viewControlPanelEmbedded superview])
        [self.view addSubview:_viewControlPanelEmbedded];

    if (![_viewBarEmbedded superview])
        [self.view addSubview:_viewBarEmbedded];

    if (![_labelStatusEmbedded superview])
        [self.view addSubview:_labelStatusEmbedded];
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
    VKFullscreenContainer *fsContainerVc = [[[VKFullscreenContainer alloc] initWithPlayerController:self] autorelease];
    UIViewController *currentVc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    UIViewController *topVc = nil;

    if (currentVc) {
        if ([currentVc isKindOfClass:[UINavigationController class]]) {
            topVc = [(UINavigationController *)currentVc topViewController];
        } else if ([currentVc isKindOfClass:[UITabBarController class]]) {
            topVc = [(UITabBarController *)currentVc selectedViewController];
        } else if ([currentVc presentedViewController]) {
            topVc = [currentVc presentedViewController];
        } else {
            VKLog(kVKLogLevelDecoder, @"Expected a view controller but not found...");
            return;
        }
    } else {
        VKLog(kVKLogLevelDecoder, @"Expected a view controller but not found...");
        return;
    }

    [self.view.superview bringSubviewToFront:self.view];
    float duration = (animated) ? 0.5 : 0.0;

    [UIView animateWithDuration:duration animations:^{
        CGRect bounds = [[UIScreen mainScreen] bounds];
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

        self.view.frame = bounds;

    } completion:^(BOOL finished) {
            [self.view removeFromSuperview];
            _containerVc = [fsContainerVc retain];

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
            if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending) {
                //running on iOS 6.0 or higher
                [topVc presentViewController:fsContainerVc animated:NO completion:NULL];
            } else {
                //running on iOS 5.x
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
                [topVc presentModalViewController:fsContainerVc animated:NO];
#endif
            }
#else
            [topVc presentModalViewController:fsContainerVc animated:NO];
#endif
            _toolBar.frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0);

            int mrgnBtPanel = 8.0;
            int hPanel = 93.0;
            int wPanel = 314.0;
            int yPanel = self.view.bounds.size.height - hPanel - mrgnBtPanel;
            int xPanel = (self.view.bounds.size.width - wPanel)/2.0;
            _viewControlPanel.frame = CGRectMake(xPanel, yPanel, wPanel, hPanel);

            if (_controlStyle != kVKPlayerControlStyleNone) {
                [self removeUIEmbedded];
                [self addUIFullScreen];
                _controlStyle = kVKPlayerControlStyleFullScreen;
            }
        [[NSNotificationCenter defaultCenter] postNotificationName:kVKPlayerDidEnterFullscreenNotification object:nil userInfo:nil];
    }];
}

- (void)addScreenControlGesturesToView:(UIView *)viewGesture {
    _doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    _doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    [viewGesture addGestureRecognizer:_doubleTapGestureRecognizer];
    _singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    _singleTapGestureRecognizer.numberOfTapsRequired = 1;
    [_singleTapGestureRecognizer requireGestureRecognizerToFail:_doubleTapGestureRecognizer];
    [viewGesture addGestureRecognizer:_singleTapGestureRecognizer];
    _pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    [viewGesture addGestureRecognizer:_pinchGestureRecognizer];
}

- (void)removeScreenControlGesturesFromView:(UIView *)viewGesture {
    if (_singleTapGestureRecognizer) {
        [viewGesture removeGestureRecognizer:_singleTapGestureRecognizer];
        [_singleTapGestureRecognizer release];
        _singleTapGestureRecognizer = nil;
    }
    if (_doubleTapGestureRecognizer) {
        [viewGesture removeGestureRecognizer:_doubleTapGestureRecognizer];
        [_doubleTapGestureRecognizer release];
        _doubleTapGestureRecognizer = nil;
    }
    if (_pinchGestureRecognizer) {
        [viewGesture removeGestureRecognizer:_pinchGestureRecognizer];
        [_pinchGestureRecognizer release];
        _pinchGestureRecognizer = nil;
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

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    if (_backgroundColor) {
        [_backgroundColor release];
        _backgroundColor = nil;
    }
    _backgroundColor = [backgroundColor retain];
    self.view.backgroundColor = _backgroundColor;
    if (_renderView) {
        _renderView.backgroundColor = _backgroundColor;
    }
}

#pragma mark Subview & timer actions

- (IBAction)onBarButtonsTapped:(id)sender {

    int tag = [(UIBarButtonItem *)sender tag];

    if (tag == BAR_BUTTON_TAG_DONE) {
        if (_containerVc && ([NSStringFromClass([_containerVc class]) isEqualToString:@"VKPlayerViewController"])) {
            [[UIApplication sharedApplication] setStatusBarHidden:_statusBarHiddenBefore withAnimation:UIStatusBarAnimationFade];
            [self performSelector:@selector(stop) withObject:sender afterDelay:0.1];
        } else if (_containerVc) {
            [self performSelector:@selector(setFullScreen:) withObject:NULL afterDelay:0.1];
        }
    } else if (tag == BAR_BUTTON_TAG_SCALE) {
        [self performSelector:@selector(scale)];
    }
}

- (IBAction)onControlPanelButtonsTapped:(id)sender {
    int tag = [(UIButton *)sender tag];
    if (tag == PANEL_BUTTON_TAG_PP_TOGGLE) {
        [self performSelector:@selector(togglePause)];
    } else if (tag == PANEL_BUTTON_TAG_INFO) {
        [self performSelector:@selector(showInfoView)];
    } else if (tag == PANEL_BUTTON_TAG_FULLSCREEN) {
        [self setFullScreen:YES];
    }
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

    //Embedded
    _buttonPanelPPEmbedded.enabled = enabled;
    _buttonScaleEmbedded.enabled = enabled;
}

- (void)startElapsedTimer {
    [self stopElapsedTimer];
    _timerElapsedTime = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(onTimerElapsedFired:) userInfo:nil repeats:YES] retain];
}

- (void)stopElapsedTimer {
    if (_timerElapsedTime && [_timerElapsedTime isValid]) {
        [_timerElapsedTime invalidate];
    }
    [_timerElapsedTime release];
    _timerElapsedTime = nil;
}

- (void)startDurationTimer {
    [self stopDurationTimer];
    _timerDuration = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(onTimerDurationFired:) userInfo:nil repeats:YES] retain];
}

- (void)stopDurationTimer {
    if (_timerDuration && [_timerDuration isValid]) {
        [_timerDuration invalidate];
    }
    [_timerDuration release];
    _timerDuration = nil;
    _labelElapsedTime.text = @"00:00";
    _labelElapsedTimeEmbedded.text = _labelElapsedTime.text;
}

- (void)showInfoView {
    if (_viewInfo && _viewInfo.hidden) {
        _viewInfo.alpha = 0.0;
        _viewInfo.hidden = NO;

        NSMutableDictionary *streamInfo = [_decodeManager streamInfo];
        NSNumber *downloadedData = [NSNumber numberWithUnsignedLong:_decodeManager.totalBytesDownloaded];
        [streamInfo setObject:downloadedData forKey:STREAMINFO_KEY_DOWNLOAD];
        [_viewInfo updateSubviewsWithInfo:streamInfo];

        [UIView animateWithDuration:0.4 animations:^{
            _viewInfo.alpha = 1.0;
        }];

        if (_timerInfoViewUpdate && [_timerInfoViewUpdate isValid]) {
            [_timerInfoViewUpdate invalidate];
        }
        [_timerInfoViewUpdate release];
        _timerInfoViewUpdate = nil;

        _timerInfoViewUpdate = [[NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(updateStreamInfoView) userInfo:nil repeats:YES] retain];
    }
}

- (void)hideInfoView {
    if (_viewInfo && !_viewInfo.hidden) {
        [UIView animateWithDuration:0.4 animations:^{
            _viewInfo.alpha = 0.0;
        } completion:^(BOOL finished) {
            _viewInfo.hidden = YES;
        }];
        if (_timerInfoViewUpdate && [_timerInfoViewUpdate isValid]) {
            [_timerInfoViewUpdate invalidate];
        }
        [_timerInfoViewUpdate release];
        _timerInfoViewUpdate = nil;
    }
}

- (void)updateStreamInfoView {
    NSMutableDictionary *streamInfo = [_decodeManager streamInfo];
    NSNumber *downloadedData = [NSNumber numberWithUnsignedLong:_decodeManager.totalBytesDownloaded];
    [streamInfo setObject:downloadedData forKey:STREAMINFO_KEY_DOWNLOAD];
    [_viewInfo updateSubviewsWithInfo:streamInfo];
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

#pragma mark Timers callbacks

- (void)onTimerPanelHiddenFired:(NSTimer *)timer {
    [self showControlPanel:NO willExpire:YES];
}

- (void)onTimerElapsedFired:(NSTimer *)timer {
    _elapsedTime = _elapsedTime + 1;
    _labelElapsedTime.text = [NSString stringWithFormat:@"%02d:%02d", _elapsedTime/60, (_elapsedTime % 60)];
    _labelElapsedTimeEmbedded.text = _labelElapsedTime.text;
}

- (void)onTimerDurationFired:(NSTimer *)timer {

    if (_decoderState == kVKDecoderStatePlaying) {
        _durationCurrent = (_decodeManager) ? [_decodeManager masterClock] : 0.0;
        _labelStreamCurrentTime.text = [NSString stringWithFormat:@"%02d:%02d", (int)_durationCurrent/60, ((int)_durationCurrent % 60)];
        _labelStreamCurrentTimeEmbedded.text = _labelStreamCurrentTime.text;
        if(!_sliderDurationCurrentTouched) {
            _sliderCurrentDuration.value = _durationCurrent;
            _sliderCurrentDurationEmbedded.value = _sliderCurrentDuration.value;
        }
    }
}

#pragma mark - Public Player instant action methods

- (void)play {

    if (_playingIsInProgress){
        VKLog(kVKLogLevelDecoder, @"_playingIsInProgress - return");
        return;
    }

    dispatch_async(_playStopQueue, ^(void) {
        VKLog(kVKLogLevelDecoder, @"dispatch_async - play()");
        _playingIsInProgress = YES;

        [UIApplication sharedApplication].idleTimerDisabled = YES;
        _elapsedTime = 0;
        _durationCurrent = 0.0;
        _durationTotal = 0.0;
        _sliderDurationCurrentTouched = NO;
        _mainScreenIsMobile = YES;

        /* Create decoder with parameters */
        _decodeManager = [[VKAVDecodeManager alloc] init];
        _decodeManager.initialPlaybackTime = (_initialPlaybackTime > 0) ? _initialPlaybackTime * NSEC_PER_MSEC : AV_NOPTS_VALUE;
        _decodeManager.autoStopAtEnd = _autoStopAtEnd;
        _decodeManager.loopPlayback = _loopPlayback;
        _decodeManager.delegate = self;

        //extra parameters
        _decodeManager.avPacketCountLogFrequency = 0.01;
        [_decodeManager setLogLevel:kVKLogLevelStateChanges|kVKLogLevelDecoder];

        VKError error = [_decodeManager connectWithStreamURLString:_contentURLString options:_decodeOptions];

        dispatch_sync(dispatch_get_main_queue(), ^{

            if (error == kVKErrorNone) {
                //create glview to render video pictures
                _renderView = [[VKGLES2View alloc] initWithFrame:self.view.bounds];
                _renderView.backgroundColor = _backgroundColor;
                if ([_renderView initGLWithDecodeManager:_decodeManager] == kVKErrorNone) {

                    [self.view insertSubview:_renderView atIndex:0];
                    [self addScreenControlGesturesToView:_renderView];

                    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
                    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
                    if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending) {
                        //running on iOS 6.x or higher
                        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interruption:) name:AVAudioSessionInterruptionNotification object:nil];
                    } else {
                        //running on iOS 5.x
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
                        audioSession.delegate = self;
#endif
                    }
#else
                    audioSession.delegate = self;
#endif
                    NSError *error;
                    if(![audioSession setCategory:AVAudioSessionCategoryPlayback error:&error]) {
                        VKLog(kVKLogLevelDecoder, @"Error: Audio Session category could not be set: %@", error.localizedDescription);
                    }
                    
                    NSTimeInterval preferredBufferDuration = .04;
                    if (![audioSession setPreferredIOBufferDuration: preferredBufferDuration error: &error]) {
                        VKLog(kVKLogLevelDecoder, @"Error: Audio Session prefered buffer duration could not be set: %@", error.localizedDescription);
                    }
                    
                    if(![audioSession setActive:YES error:&error]) {
                        VKLog(kVKLogLevelDecoder, @"Error: Audio Session could not be activated: %@", error.localizedDescription);
                    }
                    
                    //readPackets and start decoding
                    [_decodeManager performSelector:@selector(start)];

                    [self screenDidChange:nil];
                    // Register for screen connect and disconnect notifications.
                    [[NSNotificationCenter defaultCenter] addObserver:self
                                                             selector:@selector(screenDidChange:)
                                                                 name:UIScreenDidConnectNotification
                                                               object:nil];

                    [[NSNotificationCenter defaultCenter] addObserver:self
                                                             selector:@selector(screenDidChange:)
                                                                 name:UIScreenDidDisconnectNotification
                                                               object:nil];
                } else
                    VKLog(kVKLogLevelDecoder, @"onERRorr status = 1");
            } else
                VKLog(kVKLogLevelDecoder, @"onERRorr status = 2");
        });
        _playingIsInProgress = NO;
    });
}

- (void)togglePause {
    [_decodeManager performSelector:@selector(togglePause)];
}

- (void)stop {

    if (_stoppingIsInPlaying){
        VKLog(kVKLogLevelDecoder, @"_stoppingIsInPlaying - return");
        return;
    }

    [self stopElapsedTimer];
    [self stopDurationTimer];
    
    _stoppingIsInPlaying = YES;
    [_decodeManager abort];

    dispatch_async(_playStopQueue, ^(void) {
        VKLog(kVKLogLevelDecoder, @"dispatch_async - stop()");
        [_decodeManager stop];
        
        NSError *error;
        BOOL err = [[AVAudioSession sharedInstance] setActive:NO error:&error];
        if (!err) VKLog(kVKLogLevelDecoder, @"AudioSession error: %@, code: %d", error.domain, error.code);

        dispatch_sync(dispatch_get_main_queue(), ^{
            
            [UIApplication sharedApplication].idleTimerDisabled = NO;
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            
            [self removeScreenControlGesturesFromView:_renderView];
            [self removeScreenControlGesturesFromView:_viewInfo];

            if (_renderView) {
                [_renderView shutdown];
                if ([_renderView superview]) {
                    [_renderView removeFromSuperview];
                }
                [_renderView  release];
                _renderView = nil;
            }

            _decodeManager.delegate = nil;
            [_decodeManager release];
            _decodeManager = nil;

            if (_containerVc && ([NSStringFromClass([_containerVc class]) isEqualToString:@"VKPlayerViewController"])) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
                if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending) {
                    //running on iOS 6.0 or higher
                    [_containerVc dismissViewControllerAnimated:YES completion:NULL];
                } else {
                    //running on iOS 5.x
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
                    [_containerVc dismissModalViewControllerAnimated:YES];
#endif
                }
#else
                [_containerVc dismissModalViewControllerAnimated:YES];
#endif
            }
        });
        _stoppingIsInPlaying = NO;
    });
}

- (void)stepToNextFrame {
    [_decodeManager stepToNextFrame];
}

- (void)setStreamCurrentDuration:(float)value  {
    [_decodeManager doSeek:value];
}

- (void)changeAudioStream {
    [_decodeManager cycleAudioStream];
}

- (void)setMute:(BOOL)value {
    if (value) {
        [_decodeManager setVolumeLevel:0.0];
    } else {
        [_decodeManager setVolumeLevel:1.0];
    }
}

- (NSArray *)playableAudioStreams {
    return [_decodeManager playableAudioStreams];
}

- (NSArray *)playableVideoStreams {
    return [_decodeManager playableVideoStreams];
}

- (UIImage *)snapshot {
    if (!_snapshotReadyToGet) {
        return nil;
    }
    return [_renderView snapshot];
}

#pragma mark - Public Player state change methods

- (void)setInitialPlaybackTime:(int64_t)initialPlaybackTime {
    _initialPlaybackTime = initialPlaybackTime;
    if (_decodeManager)
        [_decodeManager setInitialPlaybackTime:_initialPlaybackTime];
}

- (void)setLoopPlayback:(int)loopPlayback {
    _loopPlayback = loopPlayback;
    if (_decodeManager)
        [_decodeManager setLoopPlayback:_loopPlayback];
}

- (void)setAutoStopAtEnd:(BOOL)autoStopAtEnd {
    _autoStopAtEnd = autoStopAtEnd;
    if (_decodeManager)
        [_decodeManager setAutoStopAtEnd:_autoStopAtEnd];
}

#pragma mark Public Player UI methods

- (void)scale {
    if (_renderView.contentMode == UIViewContentModeScaleAspectFit){
        _renderView.contentMode = UIViewContentModeScaleAspectFill;
        [_barButtonScale setImage:[UIImage imageNamed:@"VKImages.bundle/vk-bar-button-zoom-in.png"]];
        [_buttonScaleEmbedded setImage:[UIImage imageNamed:@"VKImages.bundle/vk-bar-button-zoom-in.png"] forState:UIControlStateNormal];
    }
    else {
        _renderView.contentMode = UIViewContentModeScaleAspectFit;
        [_barButtonScale setImage:[UIImage imageNamed:@"VKImages.bundle/vk-bar-button-zoom-out.png"]];
        [_buttonScaleEmbedded setImage:[UIImage imageNamed:@"VKImages.bundle/vk-bar-button-zoom-out.png"] forState:UIControlStateNormal];
    }
}

- (void)setControlStyle:(VKPlayerControlStyle)controlStyle {
    _controlStyle = controlStyle;
    if (_controlStyle == kVKPlayerControlStyleNone) {
        [self removeUIFullScreen];
        [self removeUIEmbedded];
    }
}

- (void)setFullScreen:(BOOL)value {
    [self setFullScreen:value animated:YES];
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
            [self removeUIEmbedded];
            [self addUIFullScreen];
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
                [(VKFullscreenContainer *)_containerVc onDismissWithAnimated:animated];
                [_containerVc release];
                _containerVc = nil;

                if (_controlStyle != kVKPlayerControlStyleNone) {
                    _controlStyle = kVKPlayerControlStyleEmbedded;
                    [self removeUIFullScreen];

                    _viewBarEmbedded.frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, 30.0);

                    float viewPanelHeight = 30.0;
                    float viewPanelEmbeddedOriginY = self.view.bounds.size.height - viewPanelHeight;
                    _viewControlPanelEmbedded.frame = CGRectMake(0.0, viewPanelEmbeddedOriginY, self.view.bounds.size.width, viewPanelHeight);

                    int hLabel = 30.0;int wLabel = 120.0;
                    int yLabel = (self.view.bounds.size.height - hLabel)/2.0; int xLabel = (self.view.bounds.size.width - wLabel)/2.0;
                    _labelStatusEmbedded.frame = CGRectMake(xLabel, yLabel, wLabel, hLabel);

                    [self performSelector:@selector(addUIEmbedded) withObject:nil afterDelay:0.4];
                }
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.9 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{

                    [[NSNotificationCenter defaultCenter] postNotificationName:kVKPlayerDidExitFullscreenNotification object:self userInfo:nil];
                });
            }
        }
    }
}

#pragma mark - gesture recognizer

- (void)handleTap:(UITapGestureRecognizer *) sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (sender == _singleTapGestureRecognizer) {
            [self showControlPanel:_panelIsHidden willExpire:YES];
        } else if (sender == _doubleTapGestureRecognizer){
            [self performSelector:@selector(scale)];
        }
    }
}

- (void)handlePinch: (UIPinchGestureRecognizer *) sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (sender == _pinchGestureRecognizer) {
            if (sender.scale > 1.0) {
                [self setFullScreen:YES];
            } else {
                [self setFullScreen:NO];
            }
        }
    }
}

#pragma mark - VKDecoder delegate methods

- (void)decoderStateChanged:(VKDecoderState)state errorCode:(VKError)errCode {
    _decoderState = state;
    if (state == kVKDecoderStateConnecting) {
        [self setPanelButtonsEnabled:NO];
         _imgViewAudioOnly.hidden = YES;
        _labelStatusEmbedded.hidden = NO;

        _labelBarTitle.text = TR(@"Loading...");
        _labelStatusEmbedded.text = _labelBarTitle.text;
        _labelBarEmbedded.text = _barTitle;

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
        VKLog(kVKLogLevelStateChanges, @"Trying to get packets");
    } else if (state == kVKDecoderStateReadyToPlay) {
        VKLog(kVKLogLevelStateChanges, @"Got enough packets to start playing");
        [_activityIndicator stopAnimating];
        [_activityIndicatorEmbedded stopAnimating];

        _labelBarTitle.frame = _viewCenteredOnBar.bounds;
        _labelBarTitle.text = _barTitle;
        _labelBarEmbedded.text = _labelBarTitle.text;

        [self startElapsedTimer];
        [self setPanelButtonsEnabled:YES];
    } else if (state == kVKDecoderStateBuffering) {
        VKLog(kVKLogLevelStateChanges, @"Buffering now...");
    } else if (state == kVKDecoderStatePlaying) {
        _labelBarTitle.text = _barTitle;
        _labelBarEmbedded.text = _labelBarTitle.text;
        VKLog(kVKLogLevelStateChanges, @"Playing now...");
        [_buttonPanelPP setImage:[UIImage imageNamed:@"VKImages.bundle/vk-panel-button-pause.png"] forState:UIControlStateNormal];
        [_buttonPanelPPEmbedded setImage:[UIImage imageNamed:@"VKImages.bundle/vk-panel-button-pause-embedded.png"] forState:UIControlStateNormal];
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
        _labelBarTitle.text = TR(@"Connection error");
        _labelStatusEmbedded.text = _labelBarTitle.text;
        _labelStatusEmbedded.hidden = NO;

        [self stopElapsedTimer];
        [self stopDurationTimer];

        [_activityIndicator stopAnimating];
        [_activityIndicatorEmbedded stopAnimating];

        [self updateBarWithDurationState:kVKErrorOpenStream];
        VKLog(kVKLogLevelStateChanges, @"Connection error - %@",errorText(errCode));
    } else if (state == kVKDecoderStateStoppedByUser) {
        [self stopElapsedTimer];
        [self stopDurationTimer];
        [self updateBarWithDurationState:kVKErrorStreamReadError];
        _labelBarEmbedded.text = @"";
        _labelStatusEmbedded.text = @"";

        [_activityIndicator stopAnimating];
        [_activityIndicatorEmbedded stopAnimating];

        VKLog(kVKLogLevelStateChanges, @"Stopped now...");
    } else if (state == kVKDecoderStateStoppedWithError) {
        if (errCode == kVKErrorStreamReadError) {
            if (_controlStyle == kVKPlayerControlStyleFullScreen) {
                NSString *title = TR(@"Error: Read error");
                NSString *body = errorText(errCode);
                UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title message:body delegate:nil cancelButtonTitle:TR(@"OK") otherButtonTitles:nil] autorelease];
                [alert show];
            }
            _labelBarTitle.text = TR(@"Error: Read error");
            _labelStatusEmbedded.text = _labelBarTitle.text;
            _labelStatusEmbedded.hidden = NO;

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
    if(_delegate && [_delegate respondsToSelector:@selector(onPlayerStateChanged:errorCode:)]) {
        [_delegate onPlayerStateChanged:state errorCode:errCode];
    }
}

#pragma mark - External Screen Management (Cable & Airplay)

- (void)screenDidChange:(NSNotification *)notification
{
    
    if (!_allowsAirPlay)
        return;

    NSArray	*screens = [UIScreen screens];
    NSUInteger screenCount = [screens count];

	if (screenCount > 1) {
        if (!_mainScreenIsMobile) return;

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
            [self removeScreenControlGesturesFromView:_renderView];
            [_renderView removeFromSuperview];
            [self addScreenControlGesturesToView:_imgViewExternalScreen];
            _imgViewExternalScreen.hidden = NO;
        }

        // Resize the GL view to fit the external screen
        _renderView.frame = self.extWindow.frame;
        // Add the GL view
        [self.extWindow addSubview:_renderView];

        // Show the window.
        [self.extWindow makeKeyAndVisible];
        [_renderView setNeedsLayout];
        _mainScreenIsMobile = NO;

	} else {
        // Release external screen and window
		self.extScreen = nil;
		self.extWindow = nil;

        if (_mainScreenIsMobile) return;

        // Configure the main window (by adding views or setting up your OpenGL ES rendering view).
        if ([_renderView superview]) {
            _imgViewExternalScreen.hidden = YES;
            [self removeScreenControlGesturesFromView:_imgViewExternalScreen];
            [_renderView removeFromSuperview];
            [self addScreenControlGesturesToView:_renderView];
        }
        // Resize the GL view to fit the iPhone/iPad screen
        _renderView.frame = self.view.frame;

        // Display the GL view on the iPhone/iPad screen
        [self.view insertSubview:_renderView atIndex:0];

        [_renderView performSelector:@selector(setNeedsLayout) withObject:nil afterDelay:1.0];
        _mainScreenIsMobile = YES;
	}
}

#pragma mark - AudioSession interruption

#pragma mark iOS 5.x Audio interruption handling

- (void)beginInterruption {
    if (_decodeManager) {
        [_decodeManager beginInterruption];
    }
}

- (void)endInterruptionWithFlags:(NSUInteger)flags {
    // re-activate audio session after interruption
    if (_decodeManager) {
        [_decodeManager endInterruptionWithFlags:flags];
    }
}

#pragma mark iOS 6.x or higher Audio interruption handling

- (void) interruption:(NSNotification*)notification
{
    if (_decodeManager) {
        [_decodeManager interruption:notification];
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
    [_barTitle release];
    [_decodeOptions release];

    [_singleTapGestureRecognizer release];
    [_doubleTapGestureRecognizer release];
    [_closeInfoViewGestureRecognizer release];

    [_backgroundColor release];
    [_renderView release];
    [_labelStatusEmbedded release];
    [_viewControlPanel release];
    [_toolBar release];
    [_viewControlPanelEmbedded release];
    [_viewBarEmbedded release];
    [_imgViewAudioOnly release];
    [_imgViewExternalScreen release];
    [_view release];
    [_contentURLString release];
    VKLog(kVKLogLevelStateChanges, @"VKPlayerController is deallocated - no more state changes captured...");

    [super dealloc];
}

@end

#pragma mark - Error descriptions

static NSString * errorText(VKError errCode)
{
    switch (errCode) {
        case kVKErrorNone:
            return @"";

        case kVKErrorUnsupportedProtocol:
            return TR(@"Protocol is not supported");
            
        case kVKErrorStreamURLParseError:
            return TR(@"Stream url or params can not be parsed");

        case kVKErrorOpenStream:
            return TR(@"Failed to connect to the stream server");

        case kVKErrorStreamInfoNotFound:
            return TR(@"Can not find any stream info");

        case kVKErrorStreamsNotAvailable:
            return TR(@"Can not open any A-V stream");

        case kVKErrorAudioCodecNotFound:
            return TR(@"Audio codec is not found");

        case kVKErrorStreamDurationNotFound:
            return TR(@"Stream duration is not found");

        case kVKErrorAudioStreamNotFound:
            return TR(@"Audio stream is not found");

        case kVKErrorVideoCodecNotFound:
            return TR(@"Video codec is not found");

        case kVKErrorVideoStreamNotFound:
            return TR(@"Video stream is not found");

        case kVKErrorAudioCodecNotOpened:
            return TR(@"Audio codec can not be opened");
            
        case kVKErrorVideoCodecNotOpened:
            return TR(@"Video codec can not be opened");
            
        case kVKErrorAudioAllocateMemory:
            return TR(@"Can not allocate memory for Audio");
            
        case kVKErrorVideoAllocateMemory:
            return TR(@"Can not allocate memory for Video");
            
        case kVKErrorUnsupportedAudioFormat:
            return TR(@"Audio format is not supported");

        case kVKErrorAudioStreamAlreadyOpened:
            return TR(@"Audio is already opened, close the current first, then open again");
            
        case kVKErroSetupScaler:
            return TR(@"Unable to setup scaler");
            
        case kVKErrorStreamReadError:
            return TR(@"Can not read from stream server");
            
        case kVKErrorStreamEOFError:
            return TR(@"End of stream");
    }
    return nil;
}
