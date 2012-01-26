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

@end

@implementation ErrorController
@synthesize desk,error;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        shouldSyncOnDisappear = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetworkStatus:) name:kReachabilityChangedNotification object:nil];
        internetReachable = [[Reachability reachabilityForInternetConnection] retain];
    }
    return self;
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    self.desk = nil;
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
    shouldSyncOnDisappear = YES;
    [self dismissModalViewControllerAnimated:YES];
}

-(IBAction)editAccount{
    LoginController* loginController = [[[LoginController alloc] initWithNibName:@"LoginView" bundle:nil] autorelease];   
    loginController.desk=self.desk;
    [self.navigationController pushViewController:loginController animated:YES];
}

- (void) checkNetworkStatus:(NSNotification *)notice{
    NetworkStatus internetStatus = [internetReachable currentReachabilityStatus];
    isInternetReachable = NO;
    isHostReachable = NO;
    isWifi = NO;
    switch (internetStatus){
        case NotReachable:
            isInternetReachable=NO;
            break;
        case ReachableViaWiFi:
            isInternetReachable = YES;
            isWifi = YES;
            break;
        case ReachableViaWWAN:
            isInternetReachable = YES;
            isWifi = NO;
            break;
    }
    [self updateView];
}



#pragma mark - View lifecycle

-(void)viewDidDisappear:(BOOL)animated{
    if (shouldSyncOnDisappear){
        [self.desk linkToModel];
        [self.desk.model sync];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    switch ([internetReachable currentReachabilityStatus]) {
        case NotReachable:
            isInternetReachable = NO;
            isWifi = NO;
            break;
        case ReachableViaWiFi:
            isInternetReachable = YES;
            isWifi = YES;
            break;
        case ReachableViaWWAN:
            isInternetReachable = YES;
            isWifi = NO;
            break;
    }
    if (!isInternetReachable){
        internetReachable = [[Reachability reachabilityForInternetConnection] retain];
        [internetReachable performSelector:@selector(startNotifier) withObject:nil afterDelay:1.5];
    }
    [self updateView];

}

- (void)viewDidLoad{
    [super viewDidLoad];
    self.navigationController.navigationBar.barStyle=UIBarStyleBlack;
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
