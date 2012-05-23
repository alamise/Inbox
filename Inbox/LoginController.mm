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

#import "LoginController.h"
#import "AppDelegate.h"
#import "DeskController.h"
#import "models.h"
#import "FlurryAnalytics.h"
#import "LoginModel.h"
#import "EmailAccountModel.h"

@implementation LoginController
@synthesize actionOnDismiss;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        shouldExecActionOnDismiss = NO;
        self.title = NSLocalizedString(@"login.title", @"");
        UIBarButtonItem* closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)];
        [self.navigationItem setRightBarButtonItem:closeButton];
        [closeButton release];
        model = [[LoginModel alloc] init];
    }
    return self;
}


-(void) close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc {
    [model release];
    self.actionOnDismiss = nil;
    [emailField release];
    [passwordField release];
    [submitButton release];
    [super dealloc];
}



#pragma mark - IBActions

- (IBAction)onLogin:(id)sender {
    if (![model validateEmail:emailField.text]){
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"login.invalidemail.title", @"title of the alert shown when the login email is invalid") message:NSLocalizedString(@"login.invalidemail.message", @"message of the alert shown when the login email is invalid") delegate:nil cancelButtonTitle:NSLocalizedString(@"login.invalidemail.button", @"button title of the alert shown when the login email is invalid") otherButtonTitles:nil];
        [alert show];
        [alert release];        
    }else if ([passwordField.text isEqualToString:@""]){
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"login.emptypassword.title","title of the alert shown when the login password is empty") message:NSLocalizedString(@"login.emptypassword.message", @"message of the alert shown when the login password is empty") delegate:nil cancelButtonTitle:NSLocalizedString(@"login.emptypassword.button", @"button title of the alert shown when the login password is empty") otherButtonTitles:nil];
        [alert show];
        [alert release];
    }else{
        NSError* error = nil;
        [model changeToGmailAccountWithLogin:emailField.text password:passwordField.text error:&error];
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

todo finish this file
-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    if (shouldExecActionOnDismiss){
        [actionOnDismiss start];
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

@end
