//
//  OtherDetailViewController.m
//  VideoKitSample
//
//  Created by Tarum Nadus on 25/11/13.
//  Copyright (c) 2013 Tarum Nadus. All rights reserved.
//

#import "OtherDetailViewController.h"

@interface OtherDetailViewController () {
    
    IBOutlet UIWebView *_webView;
    IBOutlet UIActivityIndicatorView *_indicator;
    
    NSString *_urlString;
    NSString *_title;
}

@end

@implementation OtherDetailViewController

- (id)initWithURLString:(NSString *)urlString title:(NSString *) title {
    
    self = [super initWithNibName:@"OtherDetailViewController" bundle:nil];
    if (self) {
        // Custom initialization
        _urlString = [urlString retain];
        _title = [title retain];
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
    
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_urlString]]];
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[_webView stopLoading];
	[_indicator stopAnimating];
}

#pragma mark WebView callbacks

- (void)webViewDidStartLoad:(UIWebView *)theWebView {
	[_indicator startAnimating];
    self.navigationItem.title = TR(@"Loading ...");
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:_indicator] autorelease];
}

- (void)webViewDidFinishLoad:(UIWebView *)theWebView {
    self.navigationItem.title = _title;
	self.navigationItem.rightBarButtonItem = nil;
}

- (void)webView:(UIWebView *)theWebView didFailLoadWithError:(NSError *)error {
	self.navigationItem.title = TR(@"Load failed");
	[_webView stopLoading];
	[_indicator stopAnimating];
}

#pragma mark - Memory deallocation

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_title release];
    [_urlString release];
    [_webView release];
    [_indicator release];
    [super dealloc];
}
- (void)viewDidUnload {
    [_webView release];
    _webView = nil;
    [_indicator release];
    _indicator = nil;
    [super viewDidUnload];
}
@end
