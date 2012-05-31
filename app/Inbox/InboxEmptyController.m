#import "InboxEmptyController.h"
#import "LoginController.h"
#import "FlurryAnalytics.h"

@implementation InboxEmptyController
@synthesize  actionOnDismiss;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        shouldExecActionOnDismiss = NO;
    }
    return self;
}

-(void)dealloc{
    self.actionOnDismiss = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad{
    [super viewDidLoad];
}

- (void)viewDidUnload{
    [super viewDidUnload];
}

-(void)viewDidDisappear:(BOOL)animated{
    if (shouldExecActionOnDismiss){
        [self.actionOnDismiss start];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

- (IBAction)onRefresh {
    shouldExecActionOnDismiss = YES;
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)onEditAccount {
    LoginController* loginCtr = [[[LoginController alloc] initWithNibName:@"LoginView" bundle:nil] autorelease];
    [self.navigationController pushViewController:loginCtr animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

@end
