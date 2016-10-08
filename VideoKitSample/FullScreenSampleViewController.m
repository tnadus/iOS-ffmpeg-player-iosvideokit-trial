//
//  FullScreenSampleViewController.m
//  VideoKit
//
//  Created by Murat Sudan
//  Copyright (c) 2014 iOS VideoKit. All rights reserved.
//  Elma DIGITAL
//

#import "FullScreenSampleViewController.h"

@interface FullScreenSampleViewController () {
    IBOutlet UITableView *_tableView;
}

@end

@implementation FullScreenSampleViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Fullscreen Sample";
        self.tabBarItem.title = @"Fullscreen";
        self.tabBarItem.image = [UIImage imageNamed:@"vk-tabbar-icons-fullscreen.png"];
        [self.tabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                 [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0], NSForegroundColorAttributeName,
                                                 nil] forState:UIControlStateNormal];
    }
    return self;
}

#pragma mark View life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
    self.navigationController.navigationBar.tintColor = [UIColor lightGrayColor];
    
    UIRefreshControl *refreshControl = [[[UIRefreshControl alloc] init] autorelease];
    refreshControl.tintColor = [UIColor whiteColor];
    refreshControl.attributedTitle = [[[NSAttributedString alloc] initWithString:@"Pull to refresh" attributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName, nil]] autorelease];
    [refreshControl addTarget:self action:@selector(refreshList:) forControlEvents:UIControlEventValueChanged];
    [_tableView addSubview:refreshControl];
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

        UIView *bottomLine = [[[UIView alloc] initWithFrame:CGRectMake(0.0f, 63.0f, [UIScreen mainScreen].bounds.size.height, 1.0f)] autorelease];
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

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
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
    Channel *channel = [source objectAtIndex:indexPath.row];
    NSString *urlString = [[channel urlAddress] retain];
    NSDictionary *options = [channel options];
    
    VKPlayerViewController *playerVc = [[[VKPlayerViewController alloc] initWithURLString:urlString decoderOptions:options] autorelease];
    playerVc.barTitle = [channel name];
    playerVc.statusBarHidden = YES;
    playerVc.delegate = self;
#ifdef VK_RECORDING_CAPABILITY
    playerVc.recordingEnabled = YES;
#endif
    [self.navigationController presentViewController:playerVc animated:YES completion:NULL];
    [urlString release];
}

#pragma mark - VKPlayerViewController callback

- (void)onPlayerViewControllerStateChanged:(VKDecoderState)state errorCode:(VKError)errCode {
    if (state == kVKDecoderStateConnecting) {
    } else if (state == kVKDecoderStateConnected) {
    } else if (state == kVKDecoderStateInitialLoading) {
    } else if (state == kVKDecoderStateReadyToPlay) {
    } else if (state == kVKDecoderStateBuffering) {
    } else if (state == kVKDecoderStatePlaying) {
    } else if (state == kVKDecoderStatePaused) {
    } else if (state == kVKDecoderStateStoppedByUser) {
    } else if (state == kVKDecoderStateConnectionFailed) {
    } else if (state == kVKDecoderStateStoppedWithError) {
        if (errCode == kVKErrorStreamReadError) {
        }
    }
}

#ifdef VK_RECORDING_CAPABILITY
- (void)onPlayerViewControllerDidStartRecordingWithPath:(NSString *)recordPath {
    NSLog(@"Recording started with path = %@", recordPath);
}

- (void)onPlayerViewControllerDidStopRecordingWithPath:(NSString *)recordPath error:(VKErrorRecorder)error {
    if (error == kVKErrorNone) {
        NSLog(@"Recording is ended with success");
    } else {
        NSLog(@"Recording is ended with error = %d", (int)error);
    }
}
#endif

#pragma mark Memory events

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_tableView release];
    [super dealloc];
}
- (void)viewDidUnload {
    _tableView = nil;
    [super viewDidUnload];
}
@end
