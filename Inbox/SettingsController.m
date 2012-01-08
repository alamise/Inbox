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

#import "SettingsController.h"
#import "LoginController.h"
#import "DeskController.h"
#import "MBProgressHUD.h"
#import "GmailModel.h"
#import "ErrorController.h"
#import "AppDelegate.h"

@interface SettingsController()
-(NSString*)lastSyncValue:(NSDate*)date;
-(void)reloadFromModel;
@end

@implementation SettingsController
@synthesize desk;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)];
        resync = false;
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
    [self unlinkToModel];
    [self.desk linkToModel];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - View lifecycle

- (void)viewDidLoad{
    [super viewDidLoad];
    hud = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:hud];
    inboxCountLabel.text = NSLocalizedString(@"settings.inboxcountlabel",@"");
    accountLabel.text = NSLocalizedString(@"settings.accountLabel",@"");
    lastSyncLabel.text = NSLocalizedString(@"settings.lastsynclabel", @"");
    [self reloadFromModel];
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

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft)||(interfaceOrientation==UIInterfaceOrientationLandscapeRight));
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self unlinkToModel];
}

-(void)linkToModel{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncDone) name:SYNC_DONE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onError) name:ERROR object:nil];
}

-(void)unlinkToModel{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SYNC_DONE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ERROR object:nil];
}


- (IBAction)sync:(id)sender {
    [hud show:YES];
    [self linkToModel];
    if (![self.desk.model isSyncing]){
        resync = false;
        [self.desk.model sync];
    }else{
        resync = true;
    }
}

-(void)syncDone{
    if (resync){
        resync = false;
        [self.desk.model sync];
    }else{
        [hud hide:YES];
        NSString* plistPath = [(AppDelegate*)[UIApplication sharedApplication].delegate plistPath];
        NSMutableDictionary* plistDic = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
        [plistDic setValue:[NSDate date] forKey:@"lastsync"];
        [plistDic writeToFile:plistPath atomically:YES];
        [self reloadFromModel];
    }
}

-(NSString*)lastSyncValue:(NSDate*)date{
    if (date==nil){
        return NSLocalizedString(@"settings.nolastsync", @"");
    }
    return [NSDateFormatter localizedStringFromDate: date dateStyle: NSDateFormatterShortStyle timeStyle: NSDateFormatterShortStyle];
}

-(void)reloadFromModel{
    inboxCountValue.text = [NSString stringWithFormat:@"%d",[self.desk.model emailsCountInFolder:@"INBOX"]];
    accountValue.text = self.desk.model.email;
    
    AppDelegate* delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    NSDictionary* dic = [NSDictionary dictionaryWithContentsOfFile:[delegate plistPath]];
    NSDate* syncDate = [dic objectForKey:@"syncDate"];
    
    lastSyncValue.text = [self lastSyncValue:syncDate];
}


- (void)onError:(NSError*)error{
    [hud hide:YES];
    ErrorController* errorController = [[ErrorController alloc] initWithNibName:@"ErrorView" bundle:nil];
    errorController.desk = self.desk;
    errorController.error = error;
    [self.navigationController pushViewController:errorController animated:YES];
}


- (IBAction)editAccount:(id)sender {
    LoginController* loginController = [[LoginController alloc] initWithNibName:@"LoginView" bundle:nil];
    loginController.desk = desk;
    [self.navigationController pushViewController:loginController animated:YES];
    
    
}
@end
