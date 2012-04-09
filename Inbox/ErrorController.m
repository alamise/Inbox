/*
 *
 * Copyright (c) 2012 Simon Watiau.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#import "ErrorController.h"
#import "Reachability.h"
#import "LoginController.h"
#import "DeskController.h"
#import "GmailModel.h"
#import "GANTracker.h"
#import "FlurryAnalytics.h"
@interface ErrorController()
-(void)updateViewWithNetworkStatus:(NetworkStatus)status;
@end

@implementation ErrorController
@synthesize actionOnDismiss;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        shouldExecActionOnDismiss = NO;
        // The network status is checked once, when the view is loaded. See the revision [master 3dac19c] for the version that listen to network events.
        internetReachable = [[Reachability reachabilityWithHostName:@"www.google.fr"] retain];
    }
    return self;
}

-(void)dealloc{
    self.actionOnDismiss = nil;
    [internetReachable release];
    [connectionIsBackView release];
    [noConnectionView release];
    [errorView release];
    [loadingView release];
    [super dealloc];
}

-(void)updateViewWithNetworkStatus:(NetworkStatus)status{
    switch (status){
        case NotReachable:
            self.view = noConnectionView;
            break;
        case ReachableViaWiFi:
            self.view = errorView;
            break;
        case ReachableViaWWAN:
            self.view = errorView;
            break;
        default:
            self.view = errorView;
            break;
    }
}

-(IBAction)dismiss{
    shouldExecActionOnDismiss = YES;
    [self dismissModalViewControllerAnimated:YES];
}

-(IBAction)editAccount{
    [[GANTracker sharedTracker] trackPageview:@"/error/edit_account" withError:nil];
    [FlurryAnalytics logEvent:@"error_edit_account" timed:NO];
    LoginController* loginController = [[LoginController alloc] initWithNibName:@"LoginView" bundle:nil];   
    loginController.actionOnDismiss = self.actionOnDismiss;
    [self.navigationController pushViewController:loginController animated:YES];
    [loginController release];
}

#pragma mark - View lifecycle

-(void)viewDidDisappear:(BOOL)animated{
    if (shouldExecActionOnDismiss){
        [actionOnDismiss start];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[GANTracker sharedTracker] trackPageview:@"/error" withError:nil];
    [FlurryAnalytics logEvent:@"error" timed:NO];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    self.navigationController.navigationBar.barStyle=UIBarStyleBlack;
    [self updateViewWithNetworkStatus:[internetReachable currentReachabilityStatus]];
}

- (void)viewDidUnload{
    [connectionIsBackView release];
    connectionIsBackView = nil;
    [noConnectionView release];
    noConnectionView = nil;
    [errorView release];
    errorView = nil;
    [loadingView release];
    loadingView = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

@end
