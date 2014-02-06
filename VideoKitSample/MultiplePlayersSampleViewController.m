//
//  MultiplePlayersSampleViewController.m
//  VideoKitSample
//
//  Created by Tarum Nadus on 14.10.2013.
//  Copyright (c) 2013 VideoKit. All rights reserved.
//

#import "MultiplePlayersSampleViewController.h"
#import "ChannelsManager.h"
#import "VKPlayerController.h"


@interface MultiplePlayersSampleViewController () {
    IBOutlet UITableView *_tableView;

    NSMutableArray *_playerList;
    NSMutableArray *_labels;
    int _selectedViewIndex;
}

@end

@implementation MultiplePlayersSampleViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.tabBarItem.title = @"Multi players";
        self.tabBarItem.image = [UIImage imageNamed:@"vk-tabbar-icons-multi.png"];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
        if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending) {
            //running on iOS 7.0 or higher
            [self.tabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                     [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0], NSForegroundColorAttributeName,
                                                     nil] forState:UIControlStateNormal];
        }
#endif
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending) {
        //running on iOS 7.0 or higher
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
#endif
    
    float widthLabel = 147.0;
    float heightLabel = 121.0;
    UIColor *textColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
    _labels = [[NSMutableArray alloc] init];

    for (int i = 0; i < 4; i++) {
        UILabel *label = [[[UILabel alloc] init] autorelease];
        label.tag = i;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
        if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending) {
            //running on iOS 6.0 or higher
            label.textAlignment = NSTextAlignmentCenter;
        } else {
            //running on iOS 5.x
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
            label.textAlignment = UITextAlignmentCenter;
#endif
        }
#else
        label.textAlignment = UITextAlignmentCenter;
#endif
        label.textColor = textColor;
        label.font = [UIFont fontWithName:@"HelveticaNeue" size:30];
        label.text = [NSString stringWithFormat:@"%d", i];
        label.backgroundColor = [UIColor clearColor];
        label.autoresizingMask =  UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        label.userInteractionEnabled = YES;

        UITapGestureRecognizer *tapGesture = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)] autorelease];
        tapGesture.numberOfTapsRequired = 1;
        tapGesture.numberOfTouchesRequired = 1;
        [label addGestureRecognizer:tapGesture];

        UIPinchGestureRecognizer *pinchGesture = [[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)] autorelease];
        [label addGestureRecognizer:pinchGesture];

        [_labels addObject:label];
    }

    _playerList = [[NSMutableArray array] retain];
    
    for (int i = 0; i < 4; i++) {
        VKPlayerController *player = [[[VKPlayerController alloc] init] autorelease];
        player.controlStyle = kVKPlayerControlStyleNone;
        player.statusBarHidden = YES;
        [_playerList addObject:player];

        if (i == 0)
            player.view.frame = CGRectMake(10.0, 20.0, widthLabel, heightLabel);
        else if (i == 1)
            player.view.frame = CGRectMake(163.0, 20.0, widthLabel, heightLabel);
        else if (i == 2)
            player.view.frame = CGRectMake(10.0, 144.0, widthLabel, heightLabel);
        else
            player.view.frame = CGRectMake(163.0, 144.0, widthLabel, heightLabel);

        [self.view addSubview:player.view];

        UILabel *label = [_labels objectAtIndex:i];
        label.frame = player.view.bounds;
        [player.view addSubview:[_labels objectAtIndex:i]];
    }

    _selectedViewIndex = 0;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPlayerEnterFullScreen:) name:kVKPlayerWillEnterFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPlayerExitFullScreen:) name:kVKPlayerDidExitFullscreenNotification object:nil];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    if (_tableView) {
        CGRect rV = self.view.bounds;
        CGRect rS = CGRectMake(163.0, 141.0, 145.0, 121.0);

        if (UIDeviceOrientationIsLandscape([self interfaceOrientation])) {
            float hSpace = 4.0;
            float oX = rS.origin.x + rS.size.width + hSpace;
            float w = rV.size.width - oX;
            _tableView.frame = CGRectMake(oX, 4.0, w, rV.size.height);
        } else {
            float vSpace = 8.0;
            float oY = rS.origin.y + rS.size.height + vSpace;
            float h = rV.size.height - oY;
            _tableView.frame = CGRectMake(0.0, oY, rV.size.width, h);
        }
    }
}

#pragma mark View actions 

- (void)handleTap:(UITapGestureRecognizer *) sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        UILabel *l = (UILabel *)sender.view;
        _selectedViewIndex = l.tag;

        [UIView animateWithDuration:0.3 delay:0.0 options: UIViewAnimationCurveEaseOut|UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             [l setTransform:CGAffineTransformMakeScale(1.6, 1.6)]; }
                         completion:^(BOOL finished) {
                             [UIView animateWithDuration:0.3 delay:0.0 options: UIViewAnimationOptionAllowUserInteraction animations:^{
                                 [l setTransform:CGAffineTransformMakeScale(0.7, 0.7)];}
                                              completion:^(BOOL finished) {
                                                  [UIView animateWithDuration:0.3 delay:0.0 options: UIViewAnimationOptionAllowUserInteraction animations:^{
                                                      [l setTransform:CGAffineTransformMakeScale(1.0, 1.0)];}
                                                                   completion:^(BOOL finished) {
                                                                   }];
                                              }];
                         }];
    }
}

- (void)handlePinch: (UIPinchGestureRecognizer *) sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (_playerList.count) {
            VKPlayerController *player = [_playerList objectAtIndex:sender.view.tag];
            if (sender.scale > 1.0) {
                [player setFullScreen:YES];
            }
        }
    }
}

#pragma mark TableView delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Local media files";
    }
    return @"Remote streaming urls";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return [[[ChannelsManager sharedManager] fileList] count];
    }
    return [[[ChannelsManager sharedManager] streamList] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"CellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId] autorelease];

        UIView *topLine = [[[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, [UIScreen mainScreen].bounds.size.height, 1.0f)] autorelease];
		topLine.backgroundColor = [UIColor colorWithRed:1.1 green:1.1 blue:1.11 alpha:0.5];
        [cell.contentView addSubview:topLine];

        UIView *bottomLine = [[[UIView alloc] initWithFrame:CGRectMake(0.0f, 43.0f, [UIScreen mainScreen].bounds.size.height, 1.0f)] autorelease];
		bottomLine.backgroundColor =[UIColor colorWithRed:0.78 green:0.78 blue:0.79 alpha:0.5];
		[cell.contentView addSubview:bottomLine];

        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:16];
        cell.detailTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        cell.detailTextLabel.textColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
    }

    NSArray *source = (indexPath.section == 0) ?  [[ChannelsManager sharedManager] fileList] : [[ChannelsManager sharedManager] streamList];
    Channel *channel = [source objectAtIndex:indexPath.row];
    cell.textLabel.text = [channel name];
    cell.detailTextLabel.text = [channel description];

    return cell;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    cell.backgroundColor = [UIColor colorWithRed:0.94 green:0.94 blue:0.95 alpha:1.0];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSArray *source = (indexPath.section == 0) ?  [[ChannelsManager sharedManager] fileList] : [[ChannelsManager sharedManager] streamList];
    Channel *channel = [source objectAtIndex:indexPath.row];
    NSString *urlString = [channel urlAddress];
    NSDictionary *options = [channel options];

    VKPlayerController *selectedPlayer = [_playerList objectAtIndex:_selectedViewIndex];

    [selectedPlayer stop];
    selectedPlayer.contentURLString = urlString;
    selectedPlayer.decoderOptions = options;
    [selectedPlayer play];
}

#pragma mark -Player callbacks

- (void)onPlayerEnterFullScreen:(NSNotification*)theNotification {
    VKPlayerController *pFull = (VKPlayerController *)theNotification.object;
    
    if ([_playerList containsObject:pFull]) {
        for (int i = 0; i < 4; i++) {
            UILabel *l = [_labels objectAtIndex:i];
            l.hidden = YES;
        }
    }
}

- (void)onPlayerExitFullScreen:(NSNotification*)theNotification {
    VKPlayerController *pFull = (VKPlayerController *)theNotification.object;
    if ([_playerList containsObject:pFull]) {
        for (int i = 0; i < 4; i++) {
            UILabel *l = [_labels objectAtIndex:i];
            l.hidden = NO;
        }
    }
}

#pragma mark Memory events

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_labels release];
    [super dealloc];
}

- (void)viewDidUnload {
    
    _tableView = nil;
    _labels = nil;
    [super viewDidUnload];
}

@end
