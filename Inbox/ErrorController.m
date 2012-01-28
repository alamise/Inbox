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
@interface ErrorController()
-(void)updateView;
-(void)saveInternetStatus:(NetworkStatus) status;
@end

@implementation ErrorController
@synthesize actionOnDismiss;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        shouldExecActionOnDismiss = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetworkStatus:) name:kReachabilityChangedNotification object:nil];
        internetReachable = [[Reachability reachabilityWithHostName:@"www.google.fr"] retain];
    }
    return self;
}

-(void)dealloc{
    self.actionOnDismiss = nil;
    [internetReachable release];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [connectionIsBackView release];
    [noConnectionView release];
    [errorView release];
    [loadingView release];
    [super dealloc];
}

-(void)updateView{
    if (!isInternetReachable){
        self.view = noConnectionView;
    }else{
        self.view = errorView;
    }
}


-(IBAction)dismiss{
    shouldExecActionOnDismiss = YES;
    [self dismissModalViewControllerAnimated:YES];
}

-(IBAction)editAccount{
    LoginController* loginController = [[[LoginController alloc] initWithNibName:@"LoginView" bundle:nil] autorelease];   
    loginController.actionOnDismiss = self.actionOnDismiss;
    [self.navigationController pushViewController:loginController animated:YES];
}

- (void) checkNetworkStatus:(NSNotification *)notice{
    NetworkStatus internetStatus = [internetReachable currentReachabilityStatus];
    [self saveInternetStatus:internetStatus];
}

-(void)saveInternetStatus:(NetworkStatus) status{
    isInternetReachable = NO;
    switch (status){
        case NotReachable:
            isInternetReachable=NO;
            break;
        case ReachableViaWiFi:
            isInternetReachable = YES;
            break;
        case ReachableViaWWAN:
            isInternetReachable = YES;
            break;
    }
    [self updateView];
}

#pragma mark - View lifecycle

-(void)viewDidDisappear:(BOOL)animated{
    if (shouldExecActionOnDismiss){
        [actionOnDismiss start];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    self.navigationController.navigationBar.barStyle=UIBarStyleBlack;
    [self saveInternetStatus:[internetReachable currentReachabilityStatus]];
    [self updateView];
    [internetReachable startNotifier];
}

- (void)viewDidUnload{
    [internetReachable stopNotifier];
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
