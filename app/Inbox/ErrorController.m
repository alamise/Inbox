#import "ErrorController.h"
#import "Reachability.h"
#import "LoginController.h"
#import "DeskController.h"
#import "FlurryAnalytics.h"
#import "Deps.h"

@interface ErrorController()
-(void)updateViewWithNetworkStatus:(NetworkStatus)status;
@end

@implementation ErrorController
@synthesize retryBlock;

- (id)initWithRetryBlock:(void(^)())retry {
    self = [self init];
    if ( self ) {
        shouldRetry = NO;
        self.retryBlock = retry;
        
        // The network status is checked once, when the view is loaded. See the revision [master 3dac19c] for the version that listen to network events.
        internetReachable = [[Reachability reachabilityWithHostName:@"www.google.fr"] retain];
        self.title = NSLocalizedString(@"error.title", @"navigation title");
    }
    return self;
}

-(void)dealloc{
    self.retryBlock = nil;
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

- (IBAction)dismiss {
    shouldRetry = YES;
    [self dismissModalViewControllerAnimated:YES];
}

-(IBAction)editAccount{
    LoginController* loginController = [[LoginController alloc] initWithNibName:@"LoginView" bundle:nil];   
    [self.navigationController pushViewController:loginController animated:YES];
    [loginController release];
}

#pragma mark - View lifecycle

-(void)viewDidDisappear:(BOOL)animated{
    if ( shouldRetry ) {
        self.retryBlock();
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
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
