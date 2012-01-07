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
#import "DeskController.h"
#import "GameConfig.h"
#import "AppDelegate.h"
#import "DeskLayer.h"
#import "MBProgressHUD.h"
#import "EmailController.h"
#import "TutorialController.h"
#import "ErrorController.h"
#import "GmailModel.h"
#import "cocos2d.h"
#import "SettingsController.h"
@interface DeskController ()
@property(nonatomic,retain,readwrite) GmailModel* model;
@end

@implementation DeskController
@synthesize model;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
	}
	return self;
}

- (void)dealloc {
    self.model = nil;
    [layer release];
    [glView removeFromSuperview];
    [glView release];
    [super dealloc];
}

-(void)nextStep{
    if ([model emailsCountInFolder:@"INBOX"]==0){
        if (isSyncing){
            isWaiting = TRUE;
            [loadingHud show:YES];
        }else{
            isWaiting = FALSE;
            [loadingHud show:NO];
            // show done view;
        }
    }else{
        isWaiting = NO;
        [loadingHud hide:YES];
        [layer putEmail:[model getLastEmailFrom:@"INBOX"]];
    }
}


-(void)openSettings{
    [self unlinkToModel];
    SettingsController* settingsController = [[SettingsController alloc] initWithNibName:@"SettingsView" bundle:nil];
    settingsController.desk = self;
    UINavigationController* navCtr = [[UINavigationController alloc] initWithRootViewController:settingsController];
    navCtr.modalPresentationStyle=UIModalPresentationFormSheet;
    navCtr.modalTransitionStyle=UIModalTransitionStyleCoverVertical;
    [self presentModalViewController:navCtr animated:YES];
}

-(void)move:(EmailModel*)m to:(NSString*)folder{
    [model move:m to:folder];
    [self performSelectorOnMainThread:@selector(nextStep) withObject:nil waitUntilDone:nil];
}

-(void)emailTouched:(EmailModel*)email{
    if (!email.htmlBody){
        [loadingHud showWhileExecuting:@selector(fetchEmailBody:) onTarget:self withObject:email animated:YES];    
    }else{
        EmailController* emailController = [[EmailController alloc] initWithEmailModel:email];
        UINavigationController* navCtr = [[UINavigationController alloc] initWithRootViewController:emailController];
        navCtr.modalPresentationStyle=UIModalPresentationFormSheet;
        navCtr.modalTransitionStyle=UIModalTransitionStyleCoverVertical;
        [self presentModalViewController:navCtr animated:YES];
    }
}

-(void)fetchEmailBody:(EmailModel*)email{
    if ([model fetchEmailBody:email]){
        EmailController* emailController = [[EmailController alloc] initWithEmailModel:email];
        UINavigationController* navCtr = [[UINavigationController alloc] initWithRootViewController:emailController];
        navCtr.modalPresentationStyle=UIModalPresentationFormSheet;
        navCtr.modalTransitionStyle=UIModalTransitionStyleCoverVertical;
        [self performSelectorOnMainThread:@selector(presentModalViewController:animated:) withObject:navCtr waitUntilDone:YES];
    }else{
//
    }

}

#pragma mark model handlers

-(void)unlinkToModel{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:INBOX_STATE_CHANGED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SYNC_STARTED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FOLDERS_READY object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SYNC_DONE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ERROR object:nil];
}

-(void)linkToModel{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newEmails) name:INBOX_STATE_CHANGED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncStarted) name:SYNC_STARTED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(foldersReady) name:FOLDERS_READY object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncDone) name:SYNC_DONE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onError) name:ERROR object:nil];
}

-(void)syncStarted{
    isSyncing = YES;
}

-(void)newEmails{
    if (isWaiting){
        [self performSelectorOnMainThread:@selector(nextStep) withObject:nil waitUntilDone:nil];
    }
}

-(void)foldersReady{
    [layer setFolders:[model folders]];
}

-(void)syncDone{
    isSyncing = NO;
    [loadingHud hide:true];
}

-(void)setNewModel{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SYNC_DONE object:nil];
    [self linkToModel];
    NSString* plistPath = [(AppDelegate*)[UIApplication sharedApplication].delegate plistPath];
    NSMutableDictionary* plistDic = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    self.model = [[GmailModel alloc] initWithAccount:[plistDic valueForKey:@"email"] password:[plistDic valueForKey:@"password"]];        
    [self.model sync];
    [self performSelectorOnMainThread:@selector(nextStep) withObject:nil waitUntilDone:nil];
}

-(void)resetModel{
    [loadingHud show:YES];
    [layer cleanDesk];
    [layer setFolders:nil];
    NSString* plistPath = [(AppDelegate*)[UIApplication sharedApplication].delegate plistPath];
    NSMutableDictionary* plistDic = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    
    if (self.model && [self.model.email isEqualToString:[plistDic valueForKey:@"email"]]){
        
        [self.model sync];
        [self performSelectorOnMainThread:@selector(nextStep) withObject:nil waitUntilDone:nil];
    }else {
        [self unlinkToModel];
        if (self.model){
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setNewModel) name:SYNC_DONE object:nil];
            [self.model sync];
        }else{
            [self setNewModel];
        }
    }
}

-(void)onError{
    isSyncing = false;
    isWaiting = false;
    ErrorController* errorController = [[ErrorController alloc] initWithNibName:@"ErrorView" bundle:nil];
    errorController.desk = self;
    UINavigationController* navigationController = [[[UINavigationController alloc] initWithRootViewController:errorController] autorelease];
    [errorController release];
    navigationController.modalPresentationStyle=UIModalPresentationFormSheet;
    [self presentModalViewController:navigationController animated:YES];
}

#pragma mark - rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft)||(interfaceOrientation==UIInterfaceOrientationLandscapeRight));
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    [layer didRotate];
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    //[layer willRotate];
}

#pragma mark - view's lifecyle

-(void)viewWillAppear:(BOOL)animated{
    self.navigationController.navigationBarHidden=YES;
    CCDirector *director = [CCDirector sharedDirector];
    CCScene *scene = [CCScene node];
    [scene addChild:layer];
    [director setOpenGLView:glView];
    glClearColor(1, 1, 1, 1);
    if (director.runningScene){
        [director replaceScene:scene];
    }else{
        [director runWithScene:scene];
    }
    [director resume];
    [layer willAppear];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    NSString* plistPath = [(AppDelegate*)[UIApplication sharedApplication].delegate plistPath];
    NSMutableDictionary* plistDic = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    [self linkToModel];
    if([plistDic valueForKey:@"email"] && [plistDic valueForKey:@"password"]){
        [self resetModel];
    }else{
        TutorialController* loginCtr = [[TutorialController alloc] initWithNibName:@"TutorialView" bundle:nil];
        loginCtr.field=self;
        UINavigationController* navCtr = [[UINavigationController alloc] initWithRootViewController:loginCtr];
        navCtr.modalPresentationStyle=UIModalPresentationFormSheet;
        [self presentModalViewController:navCtr animated:YES];
    }
    [plistDic release];
}

-(void)viewDidDisappear:(BOOL)animated{
	CCDirector *director = [CCDirector sharedDirector];
    [director popScene];
    [director pause];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    glView = [[EAGLView viewWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) pixelFormat:kEAGLColorFormatRGB565 depthFormat:0] retain];
    glView.autoresizingMask=UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:glView];
    [self setView:glView];
    layer = [[[DeskLayer alloc] initWithDelegate:self] retain];
    loadingHud = [[MBProgressHUD alloc] initWithFrame:self.view.frame];
    loadingHud.labelText = NSLocalizedString(@"field.loading.title",@"Loading title used in the loading HUD of the field");
    loadingHud.detailsLabelText = NSLocalizedString(@"field.loading.message",@"Loading message used in the loading HUD of the field");
    [self.view addSubview:loadingHud];

}

- (void)viewDidUnload {

    [super viewDidUnload];

    [layer release];
    [glView removeFromSuperview];
    [glView release];
    [loadingHud release];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end

