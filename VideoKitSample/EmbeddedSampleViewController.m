//
//  EmbeddedSampleViewController.m
//  VideoKitSample
//
//  Created by Tarum Nadus on 12.10.2013.
//  Copyright (c) 2013 VideoKit. All rights reserved.
//

#import "EmbeddedSampleViewController.h"
#import "VKPlayerController.h"
#include "ChannelsManager.h"

@interface EmbeddedSampleViewController () {
    IBOutlet UIImageView *_imgViewScreen;
    IBOutlet UITableView *_tableView;
}

@property (nonatomic, retain) VKPlayerController *player;

@end

@implementation EmbeddedSampleViewController

@synthesize player = _player;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.tabBarItem.title = @"Embedded";
        self.tabBarItem.image = [UIImage imageNamed:@"vk-tabbar-icons-embedded.png"];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
        if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending) {
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
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    if (_tableView) {
        CGRect rV = self.view.bounds;
        CGRect rS = _imgViewScreen.frame;
        
        if (UIDeviceOrientationIsLandscape([self interfaceOrientation])) {
            float hSpace = 12.0;
            float oX = rS.origin.x + rS.size.width + hSpace;
            float w = rV.size.width - oX;
            _tableView.frame = CGRectMake(oX, 4.0, w, rV.size.height);
        } else {
            float vSpace = 12.0;
            float oY = rS.origin.y + rS.size.height + vSpace;
            float h = rV.size.height - oY;
            _tableView.frame = CGRectMake(0.0, oY, rV.size.width, h);
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

    if (!_player) {
        self.player = [[[VKPlayerController alloc] initWithURLString:urlString] autorelease];
        _player.view.frame = CGRectMake(28.0, 38.0, 264.0, 167.0);
        [self.view addSubview:_player.view];
    } else {
        [_player stop];
    }

    _player.contentURLString = urlString;
    _player.decoderOptions = options;
    [_player play];
}

#pragma mark Memory events

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_imgViewScreen release];
    [_tableView release];
    [super dealloc];
}
- (void)viewDidUnload {
    _imgViewScreen = nil;
    _tableView = nil;
    [super viewDidUnload];
}


@end
