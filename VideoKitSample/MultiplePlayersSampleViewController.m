//
//  MultiplePlayersSampleViewController.m
//  VideoKitSample
//
//  Created by Murat Sudan
//  Copyright (c) 2014 iOS VideoKit. All rights reserved.
//  Elma DIGITAL
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
        [self.tabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                 [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0], NSForegroundColorAttributeName,
                                                 nil] forState:UIControlStateNormal];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    UIRefreshControl *refreshControl = [[[UIRefreshControl alloc] init] autorelease];
    refreshControl.tintColor = [UIColor whiteColor];
    refreshControl.attributedTitle = [[[NSAttributedString alloc] initWithString:@"Pull to refresh" attributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName, nil]] autorelease];
    [refreshControl addTarget:self action:@selector(refreshList:) forControlEvents:UIControlEventValueChanged];
    [_tableView addSubview:refreshControl];
    
    float widthLabel = 147.0;
    float heightLabel = 121.0;
    UIColor *textColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
    _labels = [[NSMutableArray alloc] init];

    for (int i = 0; i < 4; i++) {
        UILabel *label = [[[UILabel alloc] init] autorelease];
        label.tag = i;
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = textColor;
        label.font = [UIFont fontWithName:@"HelveticaNeue" size:30];
        label.text = [NSString stringWithFormat:@"%d", i];
        label.backgroundColor = [UIColor clearColor];
        label.autoresizingMask =  UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        label.userInteractionEnabled = YES;
        [_labels addObject:label];
    }

    _playerList = [[NSMutableArray array] retain];
    
    for (int i = 0; i < 4; i++) {
        VKPlayerController *player = [[[VKPlayerController alloc] init] autorelease];
        player.controlStyle = kVKPlayerControlStyleNone;
        player.statusBarHidden = YES;
        [_playerList addObject:player];
        
        UIView *playerView = player.view;
        playerView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:playerView];
        
        CGRect rectCurrentPlayer = CGRectZero;
        
        if (i == 0)
            rectCurrentPlayer = CGRectMake(10.0, 20.0, widthLabel, heightLabel);
        else if (i == 1)
            rectCurrentPlayer = CGRectMake(163.0, 20.0, widthLabel, heightLabel);
        else if (i == 2)
            rectCurrentPlayer = CGRectMake(10.0, 144.0, widthLabel, heightLabel);
        else
            rectCurrentPlayer = CGRectMake(163.0, 144.0, widthLabel, heightLabel);
        
        // align playerView from the left
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
                                   [NSString stringWithFormat:@"H:|-%f-[playerView(==%f)]", rectCurrentPlayer.origin.x, rectCurrentPlayer.size.width]
                                                                          options:0 metrics:nil views:NSDictionaryOfVariableBindings(playerView)]];
        // align playerView from the top
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
                                   [NSString stringWithFormat:@"V:|-%f-[playerView(==%f)]", rectCurrentPlayer.origin.y, rectCurrentPlayer.size.height] options:0 metrics:nil views:NSDictionaryOfVariableBindings(playerView)]];
        
        UILabel *label = [_labels objectAtIndex:i];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        [player.view addSubview:[_labels objectAtIndex:i]];
        
        // center label horizontally in playerView
        [playerView addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:playerView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
        // center label vertically in playerView
        [playerView addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:playerView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
        // width constraint
        [playerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[label(==20)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(label)]];
        // height constraint
        [playerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[label(==24)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(label)]];
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

        if (self.view.bounds.size.width > self.view.bounds.size.height) {
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

#pragma mark - Actions

- (void)refreshList:(id)sender {
    
    [[ChannelsManager sharedManager] updateChannelList];
    [_tableView reloadData];
    [(UIRefreshControl *)sender endRefreshing];
}

#pragma mark TableView delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Local media files";
    }
#ifdef VK_RECORDING_CAPABILITY
    else if (section == 1) {
        return @"Recorded files";
    }
#endif
    return @"Remote streaming urls";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return [[[ChannelsManager sharedManager] fileList] count];
    }
#ifdef VK_RECORDING_CAPABILITY
    else if (section == 1) {
        return [[[ChannelsManager sharedManager] recordList] count];
    }
#endif
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
        cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:18];
        cell.detailTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        cell.detailTextLabel.textColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
    }
    
    NSArray *source;
    if (indexPath.section == 0) {
        source = [[ChannelsManager sharedManager] fileList];
    }
#ifdef VK_RECORDING_CAPABILITY
    else if (indexPath.section == 1) {
        source = [[ChannelsManager sharedManager] recordList];
    }
#endif
    else {
        source = [[ChannelsManager sharedManager] streamList];
    }
    
    Channel *channel = [source objectAtIndex:indexPath.row];
    cell.textLabel.text = [channel name];
    cell.detailTextLabel.text = [channel description];
    
    return cell;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    cell.backgroundColor = [UIColor colorWithRed:0.94 green:0.94 blue:0.95 alpha:1.0];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSArray *source;
    if (indexPath.section == 0) {
        source = [[ChannelsManager sharedManager] fileList];
    }
#ifdef VK_RECORDING_CAPABILITY
    else if (indexPath.section == 1) {
        source = [[ChannelsManager sharedManager] recordList];
    }
#endif
    else {
        source = [[ChannelsManager sharedManager] streamList];
    }
    
    UILabel *l = _labels[_selectedViewIndex];
    
    [UIView animateWithDuration:0.3 delay:0.0 options: UIViewAnimationCurveEaseOut|UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         [l setTransform:CGAffineTransformMakeScale(1.6, 1.6)]; }
                     completion:^(BOOL finished) {
                         
                         Channel *channel = [source objectAtIndex:indexPath.row];
                         NSString *urlString = [channel urlAddress];
                         NSDictionary *options = [channel options];
                         
                         VKPlayerController *selectedPlayer = [_playerList objectAtIndex:_selectedViewIndex];
                         [selectedPlayer stop];
                         selectedPlayer.contentURLString = urlString;
                         selectedPlayer.decoderOptions = options;
                         [selectedPlayer play];
                         _selectedViewIndex = (_selectedViewIndex + 1)%4;
                         
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
