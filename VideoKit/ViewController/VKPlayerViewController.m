//
//  VKPlayerViewController.m
//  VideoKit
//
//  Created by Murat Sudan
//  Copyright (c) 2014 iOS VideoKit. All rights reserved.
//  Elma DIGITAL
//

#import "VKPlayerViewController.h"
#import "VKGLES2View.h"
#import "VKStreamInfoView.h"

#import <MediaPlayer/MediaPlayer.h>


@interface VKPlayerViewController ()<VKPlayerControllerDelegate> {
    NSString *_urlString;
    NSDictionary *_options;
    VKPlayerControllerBase *_playerController;
    BOOL _allowAirPlay;
    BOOL _fillScreen;
}

@end

@implementation VKPlayerViewController

@synthesize barTitle = _barTitle;
@synthesize statusBarHidden = _statusBarHidden;
@synthesize delegate = _delegate;
@synthesize allowAirPlay = _allowAirPlay;
@synthesize fillScreen = _fillScreen;
@synthesize username = _username;
@synthesize secret = _secret;

- (id)initWithURLString:(NSString *)urlString decoderOptions:(NSDictionary *)options {

    self = [super init];
    if (self) {
        // Custom initialization
        _urlString = [urlString retain];
        _options = [options retain];
#if TARGET_OS_TV
        _playerController = [[VKPlayerControllerTV alloc] initWithURLString:_urlString];
#else
        _playerController = [[VKPlayerController alloc] initWithURLString:_urlString];
#endif
        _playerController.decoderOptions = _options;
        _playerController.delegate = self;
        self.username = @"";
        self.secret = @"";
        return self;
    }
    return nil;
}

#pragma mark View life cycle


- (void)loadView {
    
    CGRect bounds = CGRectZero;
    
#if TARGET_OS_TV
    bounds = [[UIScreen mainScreen] bounds];
#else
    bounds = [[UIScreen mainScreen] applicationFrame];
    
    if (UIInterfaceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
        bounds =  CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.height, bounds.size.width);
    }
#endif
    
    self.view = [[[UIView alloc] initWithFrame:bounds] autorelease];
    self.view.backgroundColor = [UIColor blackColor];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending) {
        //running on iOS 7.0 or higher
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    _playerController.username = _username;
    _playerController.secret = _secret;
    UIView *playerView = _playerController.view;
    playerView.translatesAutoresizingMaskIntoConstraints = NO;
    _playerController.containerVc = self;
    [_playerController setFullScreen:YES];
    [self.view addSubview:playerView];
    
    // align _playerController.view from the left and right
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[playerView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(playerView)]];
    
    // align _playerController.view from the top and bottom
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[playerView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(playerView)]];

    [_playerController play];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

#pragma mark - Public methods

- (void)setBarTitle:(NSString *)barTitle {
    [_barTitle release];
    _barTitle = nil;
    _barTitle = [barTitle retain];
    _playerController.barTitle = _barTitle;
}

- (void)setStatusBarHidden:(BOOL)statusBarHidden {
    if ([_playerController respondsToSelector:@selector(isStatusBarHidden)]) {
        _statusBarHidden = statusBarHidden;
        _playerController.statusBarHidden = _statusBarHidden;
    }
}

- (void)setDelegate:(id<VKPlayerViewControllerDelegate>)delegate {
    _delegate = delegate;
}

- (void)setAllowAirPlay:(BOOL)allowAirPlay {
    _allowAirPlay = allowAirPlay;
    _playerController.allowsAirPlay = _allowAirPlay;
}

- (void)setFillScreen:(BOOL)fillScreen {
    _fillScreen = fillScreen;
    _playerController.fillScreen = _fillScreen;
}

#ifdef VK_RECORDING_CAPABILITY
- (void)setRecordingEnabled:(BOOL)recordingEnabled {
    _recordingEnabled = recordingEnabled;
    _playerController.recordingEnabled = _recordingEnabled;
}
#endif

#pragma mark View controller rotation methods & callbacks

- (BOOL)shouldAutorotate {
    return YES;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

#if !TARGET_OS_TV
- (BOOL)prefersStatusBarHidden {
    return [(VKPlayerController *)_playerController isStatusBarHidden];
}
#endif

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIDeviceOrientationPortraitUpsideDown);
}

#pragma mark - Toolbar position delegate

- (UIBarPosition)positionForBar:(id <UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}

#pragma mark - VKPlayerController callback

- (void)player:(VKPlayerControllerBase *)player didChangeState:(VKDecoderState)state errorCode:(VKError)errCode {
    if(_delegate && [_delegate respondsToSelector:@selector(onPlayerViewControllerStateChanged:errorCode:)]) {
        [_delegate onPlayerViewControllerStateChanged:state errorCode:errCode];
    }
}

#ifdef VK_RECORDING_CAPABILITY
- (void)player:(VKPlayerControllerBase *)player didStartRecordingWithPath:(NSString *)recordPath {
    if(_delegate && [_delegate respondsToSelector:@selector(onPlayerViewControllerDidStartRecordingWithPath:)]) {
        [_delegate onPlayerViewControllerDidStartRecordingWithPath:recordPath];
    }
}

- (void)player:(VKPlayerControllerBase *)player didStopRecordingWithPath:(NSString *)recordPath error:(VKErrorRecorder)error {
    if(_delegate && [_delegate respondsToSelector:@selector(onPlayerViewControllerDidStopRecordingWithPath:error:)]) {
        [_delegate onPlayerViewControllerDidStopRecordingWithPath:recordPath error:error];
    }
}
#endif

#pragma mark - Memory events & deallocation

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)dealloc {
    [_urlString release];
    [_options release];
    [_playerController release];
    [super dealloc];
}

@end