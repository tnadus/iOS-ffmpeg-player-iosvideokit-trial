//
//  OtherViewController.m
//  VideoKitSample
//
//  Created by Tarum Nadus on 07/11/13.
//  Copyright (c) 2013 Tarum Nadus. All rights reserved.
//

#import "OtherViewController.h"
#import "OtherDetailViewController.h"
#import "AppDelegate.h"
#include <QuartzCore/QuartzCore.h>


typedef enum {
    CellIndexDocumentation = 0,
    CellIndexFAQ,
    CellIndexFeedback,
    CellIndexTour,
    CellIndexAbout
} CellIndex;

@interface OtherViewController () {
    IBOutlet UIImageView *_imgViewMain;
    IBOutlet UILabel *_labelInfo;
    
    NSArray *_titles;
}

@end

@implementation OtherViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Other";
        self.tabBarItem.title = @"Other";
        self.tabBarItem.image = [UIImage imageNamed:@"vk-tabbar-icons-other.png"];
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
        self.navigationItem.rightBarButtonItem.tintColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
    }
#endif
    self.navigationController.navigationBar.tintColor = [UIColor lightGrayColor];
    _imgViewMain.layer.cornerRadius = 20.0;
    _imgViewMain.layer.masksToBounds = YES;
    
    NSString *version = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"SDK-Build"];
    _labelInfo.text = [NSString stringWithFormat:@"%@ %@", TR(@"Build date: "), version];
    _labelInfo.textColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
    
    _titles = [[NSArray alloc] initWithObjects:@"Documentation", @"F.A.Q", @"Feedback", @"Tour", @"About",  nil];
}

#pragma mark TableView delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _titles.count;
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
        
        cell.accessoryType = UITableViewCellAccessoryDetailButton;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:18];
        cell.detailTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        cell.detailTextLabel.textColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
    }
    
    cell.textLabel.text = [_titles objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    cell.backgroundColor = [UIColor colorWithRed:0.94 green:0.94 blue:0.95 alpha:1.0];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == CellIndexDocumentation) {
        OtherDetailViewController *otherDetailVc = [[[OtherDetailViewController alloc] initWithURLString:@"http://bit.ly/1gcEteF" title:[_titles objectAtIndex:indexPath.row]] autorelease];
        [self.navigationController pushViewController:otherDetailVc animated:YES];
    } else if (indexPath.row == CellIndexFAQ) {
        OtherDetailViewController *otherDetailVc = [[[OtherDetailViewController alloc] initWithURLString:@"http://bit.ly/1b0ZweR" title:[_titles objectAtIndex:indexPath.row]] autorelease];
        [self.navigationController pushViewController:otherDetailVc animated:YES];
    } else if (indexPath.row == CellIndexFeedback) {
        OtherDetailViewController *otherDetailVc = [[[OtherDetailViewController alloc] initWithURLString:@"http://bit.ly/17O9Nht" title:[_titles objectAtIndex:indexPath.row]] autorelease];
        [self.navigationController pushViewController:otherDetailVc animated:YES];
    } else if (indexPath.row == CellIndexTour) {
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate performSelector:@selector(addIntroView:) withObject:self];
    } else if (indexPath.row == CellIndexAbout) {
        OtherDetailViewController *otherDetailVc = [[[OtherDetailViewController alloc] initWithURLString:@"http://bit.ly/1jCWRNx" title:[_titles objectAtIndex:indexPath.row]] autorelease];
        [self.navigationController pushViewController:otherDetailVc animated:YES];
    }
    
}

#pragma mark Memory deallocation

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_titles release];
    [_imgViewMain release];
    [_labelInfo release];
    [super dealloc];
}

- (void)viewDidUnload {
    [_imgViewMain release];
    _imgViewMain = nil;
    [_labelInfo release];
    _labelInfo = nil;
    [super viewDidUnload];
}
@end
