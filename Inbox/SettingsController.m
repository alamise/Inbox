//
//  SettingsController.m
//  Inbox
//
//  Created by Simon Watiau on 12/29/11.
//

#import "SettingsController.h"

@implementation SettingsController

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
}

- (IBAction)editAccount:(id)sender {
}
@end
