//
//  ErrorController.m
//  gmailbattlefield
//
//  Created by Simon Watiau on 12/26/11.
//

#import "ErrorController.h"
#import "Reachability.h"
#import "LoginController.h"
#import "BattlefieldController.h"
@interface ErrorController()
-(void)updateView;

@end

@implementation ErrorController
@synthesize field;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetworkStatus:) name:kReachabilityChangedNotification object:nil];
        internetReachable = [[Reachability reachabilityForInternetConnection] retain];
    }
    return self;
}

-(void)dealloc{
    self.field = nil;
    [connectionIsBackView release];
    [noConnectionView release];
    [errorView release];
    [loadingView release];
    [super dealloc];
}

-(void)viewDidAppear:(BOOL)animated{
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

-(void)updateView{
    if (!isInternetReachable){
        self.view = noConnectionView;
    }else{
        self.view = errorView;
    }
}

-(IBAction)dismiss{
    [self.field reload];
    [self dismissModalViewControllerAnimated:YES];
}

-(IBAction)editAccount{
    LoginController* loginController = [[LoginController alloc] initWithNibName:@"LoginView" bundle:nil];   
    loginController.field=self.field;
    [self.navigationController pushViewController:loginController animated:YES];
    [loginController release];
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

- (void)viewDidLoad{
    [super viewDidLoad];
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
