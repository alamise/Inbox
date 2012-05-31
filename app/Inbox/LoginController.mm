#import "LoginController.h"
#import "AppDelegate.h"
#import "DeskController.h"
#import "FlurryAnalytics.h"
#import "LoginModel.h"
#import "EmailAccountModel.h"
#import "Deps.h"
#import "SynchroManager.h"
#import "ErrorController.h"

@implementation LoginController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        shouldExecActionOnDismiss = NO;
        self.title = NSLocalizedString(@"login.title", @"Navigation title");
        UIBarButtonItem* closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)];
        [self.navigationItem setRightBarButtonItem:closeButton];
        [closeButton release];
        model = [[LoginModel alloc] init];
    }
    return self;
}


- (void)dealloc {
    [model release];
    [emailField release];
    [passwordField release];
    [submitButton release];
    [super dealloc];
}

#pragma mark - IBActions

- (void)close {
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)onLogin:(id)sender {
    if (![model validateEmail:emailField.text]){
        [self onInvalidEmail];       
    }else if ([passwordField.text isEqualToString:@""]){
        [self onInvalidPassword];
    }else{
        NSError *error = nil; 
        [model changeToGmailAccountWithLogin:emailField.text password:passwordField.text error:&error];
        if ( error ) {
            [self onUnknownError];
        }
        shouldExecActionOnDismiss = YES;
        [self dismissModalViewControllerAnimated:YES];
    }
}

-(IBAction)openSecurityPage{
    [FlurryAnalytics logEvent:@"security" timed:NO];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/simon-watiau/Inbox/wiki/aboutsecurity"]];
}


#pragma mark - View's lifecycle

- (void)viewDidLoad{
    [super viewDidLoad];
    NSError* error = nil;
    EmailAccountModel* account = [model firstAccountWithError:&error];
    if ( !error && account ) {
        emailField.text = account.login;
        passwordField.text = account.password;
    }
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    if ( shouldExecActionOnDismiss ) {
        [[Deps sharedInstance].synchroManager abortSync:^{
            NSError* error = nil;
            [[Deps sharedInstance].synchroManager reloadAccountsWithError:&error];
            if ( error ) {
                [self onUnknownError];
            }        
        }];
    }
}

- (void)viewDidUnload{
    [passwordField release];
    passwordField = nil;
    [submitButton release];
    submitButton = nil;
    [emailField release];
    emailField = nil;
    [super viewDidUnload];
}


#pragma mark messages

- (void)onInvalidPassword {
    NSString *title = NSLocalizedString(@"login.error.emptypassword.title","");
    NSString *message = NSLocalizedString(@"login.error.emptypassword.message", @"");
    NSString *ok = NSLocalizedString(@"login.error.emptypassword.button", @"");
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:ok, nil];
    [alert show];
    [alert release];
}

- (void)onInvalidEmail {
    NSString *title = NSLocalizedString(@"login.error.invalidemail.title", @"");
    NSString *message = NSLocalizedString(@"login.error.invalidemail.message", @"");
    NSString *ok = NSLocalizedString(@"login.error.invalidemail.button", @"");
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:ok, nil];
    [alert show];
    [alert release]; 
}

- (void)onUnknownError {
    NSString *title = NSLocalizedString(@"login.error.unknown.title","");
    NSString *message = NSLocalizedString(@"login.error.unknown.message", @"");
    NSString *ok = NSLocalizedString(@"login.error.unknown.button", @"");
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:ok, nil];
    [alert show];
    [alert release];    
}

@end
