//
//  LoginController.m
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/27/11.
//

#import "LoginController.h"
#import "AppDelegate.h"
#import "DeskController.h"
@implementation LoginController
@synthesize field;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)dealloc {
    self.field = nil;
    [emailField release];
    [passwordField release];
    [submitButton release];
    [emailField release];
    [super dealloc];
}


#pragma mark - View lifecycle

- (void)viewDidLoad{
    NSString* plistPath = [(AppDelegate*)[UIApplication sharedApplication].delegate getPlistPath];
    NSMutableDictionary* plistDic = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    if (plistPath){
        emailField.text = [plistDic valueForKey:@"email"];
        passwordField.text = [plistDic valueForKey:@"password"];
    }
    [super viewDidLoad];
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
    return ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft)||(interfaceOrientation==UIInterfaceOrientationLandscapeRight));
}

- (BOOL) validateEmail: (NSString *) candidate {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@gmail\\.com";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex]; 
    
    return [emailTest evaluateWithObject:candidate];
}


#pragma mark - IBActions

- (IBAction)onLogin:(id)sender {
    if (![self validateEmail:emailField.text]){
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"login.invalidemail.title", @"title of the alert shown when the login email is invalid") message:NSLocalizedString(@"login.invalidemail.message", @"message of the alert shown when the login email is invalid") delegate:nil cancelButtonTitle:NSLocalizedString(@"login.invalidemail.button", @"button title of the alert shown when the login email is invalid") otherButtonTitles:nil];
        [alert show];
        [alert release];
        
    }else if ([passwordField.text isEqualToString:@""]){
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"login.emptypassword.title","title of the alert shown when the login password is empty") message:NSLocalizedString(@"login.emptypassword.message", @"message of the alert shown when the login password is empty") delegate:nil cancelButtonTitle:NSLocalizedString(@"login.emptypassword.button", @"button title of the alert shown when the login password is empty") otherButtonTitles:nil];
        [alert show];
        [alert release];
    }else{
        NSString* plistPath = [(AppDelegate*)[UIApplication sharedApplication].delegate getPlistPath];
        NSMutableDictionary* plistDic = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
        [plistDic setValue:emailField.text forKey:@"email"];
        [plistDic setValue:passwordField.text forKey:@"password"];
        [plistDic writeToFile:plistPath atomically:YES];
        [plistDic release];
        [self.field reload];
        [self dismissModalViewControllerAnimated:YES];
    }
}
@end
