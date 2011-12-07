//
//  LoginController.m
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/27/11.
//

#import "LoginController.h"
#import "AppDelegate.h"
#import "BattlefieldController.h"
@implementation LoginController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)dealloc {
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
    return YES;
}

#pragma mark - IBActions

- (IBAction)onLogin:(id)sender {
    NSString* plistPath = [(AppDelegate*)[UIApplication sharedApplication].delegate getPlistPath];
    NSMutableDictionary* plistDic = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    [plistDic setValue:emailField.text forKey:@"email"];
    [plistDic setValue:passwordField.text forKey:@"password"];
    [plistDic writeToFile:plistPath atomically:YES];
    [plistDic release];
    BattlefieldController* battlefield = [[BattlefieldController alloc] init];
    [self.navigationController pushViewController:battlefield animated:YES];
    [battlefield release];
}
@end
