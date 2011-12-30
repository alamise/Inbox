//
//  SettingsController.m
//  Inbox
//
//  Created by Simon Watiau on 12/29/11.
//

#import "SettingsController.h"
#import "LoginController.h"
#import "DeskController.h"
#import "MBProgressHUD.h"
#import "GmailModel.h"
@implementation SettingsController
@synthesize desk;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)];
    }
    return self;
}

- (void)dealloc {
    [inboxCountValue release];
    [inboxCountLabel release];
    [accountLabel release];
    [accountValue release];
    [lastSyncLabel release];
    [lastSyncValue release];
    [super dealloc];
}

-(void)close{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - View lifecycle

- (void)viewDidLoad{
    [super viewDidLoad];
    hud = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:hud];
}

- (void)viewDidUnload{
    [inboxCountValue release];
    inboxCountValue = nil;
    [inboxCountLabel release];
    inboxCountLabel = nil;
    [accountLabel release];
    accountLabel = nil;
    [accountValue release];
    accountValue = nil;
    [lastSyncLabel release];
    lastSyncLabel = nil;
    [lastSyncValue release];
    lastSyncValue = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
	return YES;
}

- (IBAction)sync:(id)sender {
    [hud show:YES];
    [desk.model sync];
}

- (void)onError:(NSString*)errorMessage{
}

-(void)syncDone{
    [hud hide:YES];
}

- (IBAction)editAccount:(id)sender {
    LoginController* loginController = [[LoginController alloc] initWithNibName:@"LoginView" bundle:nil];
    loginController.field = desk;
    [self.navigationController pushViewController:loginController animated:YES];
    
    
}
@end
