#import "EmailController.h"
#import "Deps.h"
#import "CoreDataManager.h"
#import "FlurryAnalytics.h"

@implementation EmailController
-(id)initWithEmail:(NSManagedObjectID*)email{
    if (self = [super initWithNibName:@"EmailView" bundle:nil]){
        self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)];
    
        emailId = [email retain];
    }
    return self;
}
-(void)dealloc{
    [webView release];
    [emailId release];
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad{
    [super viewDidLoad];
    NSManagedObjectContext* context = [[Deps sharedInstance].coreDataManager mainContext];
    EmailModel* email = (EmailModel*)[context objectWithID:emailId];
    [webView loadHTMLString:email.htmlBody baseURL:nil];
    self.navigationController.navigationBar.barStyle=UIBarStyleBlack;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [FlurryAnalytics logEvent:@"show email" timed:NO];
}

- (void)viewDidUnload{
    [super viewDidUnload];
    [webView release];
    webView = nil;
}

-(void)close{
    [self dismissModalViewControllerAnimated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft)||(interfaceOrientation==UIInterfaceOrientationLandscapeRight));
}

@end
