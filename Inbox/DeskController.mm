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
#import "InboxEmptyController.h"
#import "LoginController.h"

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
    [self.model stopSync];
    self.model = nil;
    [layer release];
    [glView removeFromSuperview];
    [glView release];
    [super dealloc];
}

-(void)openSettings{
    [self unlinkToModel];
    LoginController* loginController = [[LoginController alloc] initWithNibName:@"LoginView" bundle:nil];
    loginController.desk = self;
    UINavigationController* navCtr = [[UINavigationController alloc] initWithRootViewController:loginController];
    navCtr.modalPresentationStyle=UIModalPresentationFormSheet;
    navCtr.modalTransitionStyle=UIModalTransitionStyleCoverVertical;
    [self presentModalViewController:navCtr animated:YES];
}

-(void)move:(EmailModel*)m to:(NSString*)folder{
    [model move:m to:folder];
    [self performSelectorOnMainThread:@selector(nextStep) withObject:nil waitUntilDone:nil];
}

-(void)showEmail:(EmailModel*)email{
    if (!email.htmlBody){
        [loadingHud showWhileExecuting:@selector(fetchEmailBody:) onTarget:self withObject:email animated:YES];    
    }else{
        EmailController* emailController = [[EmailController alloc] initWithEmailModel:email];
        UINavigationController* navCtr = [[UINavigationController alloc] initWithRootViewController:emailController];
        [navCtr.navigationBar setBarStyle:UIBarStyleBlack];
        navCtr.modalPresentationStyle=UIModalPresentationPageSheet;
        navCtr.modalTransitionStyle=UIModalTransitionStyleCoverVertical;
        [self presentModalViewController:navCtr animated:YES];
    }
}


-(void)emailTouched:(EmailModel*)email{
    [self performSelectorOnMainThread:@selector(showEmail:) withObject:email waitUntilDone:YES]; 
}

-(void)fetchEmailBody:(EmailModel*)email{
    if ([model fetchEmailBody:email]){
        [self performSelectorOnMainThread:@selector(showEmail:) withObject:email waitUntilDone:YES];
    }else{
        [self unlinkToModel];
        ErrorController* errorController = [[ErrorController alloc] initWithNibName:@"ErrorView" bundle:nil];
        errorController.desk = self;
        UINavigationController* navCtr = [[UINavigationController alloc] initWithRootViewController:errorController];
        [navCtr.navigationBar setBarStyle:UIBarStyleBlack];
        navCtr.modalPresentationStyle=UIModalPresentationPageSheet;
        navCtr.modalTransitionStyle=UIModalTransitionStyleCoverVertical;
        [self presentModalViewController:navCtr animated:YES];
    }
}


-(void)showLoadingHud{
    layer.isActive = NO;
    [loadingHud show:YES];
}

-(void)hideLoadingHud{
    layer.isActive = YES;
    [loadingHud hide:YES];
}


#pragma mark model handlers

-(void)unlinkToModel{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:INBOX_STATE_CHANGED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SYNC_STARTED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FOLDERS_READY object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SYNC_DONE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SYNC_ABORTED object:nil];
}

-(void)linkToModel{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inboxChanged) name:INBOX_STATE_CHANGED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncStarted) name:SYNC_STARTED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(foldersReady) name:FOLDERS_READY object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncDone) name:SYNC_DONE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onError) name:SYNC_ABORTED object:nil];
}

-(void)syncStarted{
    isWaiting = TRUE;
    [self performSelectorOnMainThread:@selector(showLoadingHud) withObject:nil waitUntilDone:YES];
    [self performSelectorOnMainThread:@selector(nextStep) withObject:nil waitUntilDone:YES];
}

-(void)inboxChanged{
    [self performSelectorOnMainThread:@selector(nextStep) withObject:nil waitUntilDone:nil];
}

-(void)syncDone{
    [self performSelectorOnMainThread:@selector(nextStep) withObject:nil waitUntilDone:nil];
}

-(void)foldersReady{
    [layer setFolders:[model folders]];
}

-(void)nextStep{
    if ([layer mailsOnSceneCount]!=0) return;
    if ([model emailsCountInFolder:NSLocalizedString(@"folderModel.path.inbox", @"Localized Inbox folder's path en: \"INBOX\"")]==0){
        if ([model isSyncing]){
            isWaiting = YES;
            [self performSelectorOnMainThread:@selector(showLoadingHud) withObject:nil waitUntilDone:YES];    
        }else{
            isWaiting = NO;
            [self performSelectorOnMainThread:@selector(hideLoadingHud) withObject:nil waitUntilDone:YES];
            [self unlinkToModel];
            InboxEmptyController* inboxEmptyController = [[InboxEmptyController alloc] initWithNibName:@"InboxEmptyView" bundle:nil];
            inboxEmptyController.desk = self;
            UINavigationController* navCtr = [[UINavigationController alloc] initWithRootViewController:inboxEmptyController];
            [navCtr.navigationBar setBarStyle:UIBarStyleBlack];
            navCtr.modalPresentationStyle=UIModalPresentationPageSheet;
            navCtr.modalTransitionStyle=UIModalTransitionStyleCoverVertical;
            [self presentModalViewController:navCtr animated:YES];
        }
    }else{
        isWaiting = NO;
        [self performSelectorOnMainThread:@selector(hideLoadingHud) withObject:nil waitUntilDone:YES];
        [layer putEmail:[model getLastEmailFrom:NSLocalizedString(@"folderModel.path.inbox", @"Localized Inbox folder's path en: \"INBOX\"")]];
    }
}

-(void)setNewModel{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SYNC_DONE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SYNC_ABORTED object:nil];
    [self linkToModel];
    [(AppDelegate*)[UIApplication sharedApplication].delegate resetDatabase];
    NSString* plistPath = [(AppDelegate*)[UIApplication sharedApplication].delegate plistPath];
    NSMutableDictionary* plistDic = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    self.model = [[[GmailModel alloc] initWithAccount:[plistDic valueForKey:@"email"] password:[plistDic valueForKey:@"password"]] autorelease];
    [plistDic release];
    [self.model sync];
}

-(void)resetModel{
    [self unlinkToModel];
    [layer cleanDesk];
    if (self.model && [self.model isSyncing]){
        [self showLoadingHud];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setNewModel) name:SYNC_DONE object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onError) name:SYNC_ABORTED object:nil];
        [self.model stopSync];
    }else{
        [self setNewModel];
    }
}

-(void)onError{
    [self performSelectorOnMainThread:@selector(presentErrorView) withObject:nil waitUntilDone:NO];
}

-(void)presentErrorView{
    [self unlinkToModel];
    isSyncing = false;
    isWaiting = false;
    [self performSelectorOnMainThread:@selector(hideLoadingHud) withObject:nil waitUntilDone:YES];
    ErrorController* errorController = [[ErrorController alloc] initWithNibName:@"ErrorView" bundle:nil];
    errorController.desk = self;
    UINavigationController* navigationController = [[[UINavigationController alloc] initWithRootViewController:errorController] autorelease];
    [errorController release];
    navigationController.modalPresentationStyle=UIModalPresentationFormSheet;
    [self presentModalViewController:navigationController animated:YES];
}


#pragma mark - view's lifecyle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft)||(interfaceOrientation==UIInterfaceOrientationLandscapeRight));
}

-(void)viewWillAppear:(BOOL)animated{
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
    [layer setOrUpdateScene];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    NSString* plistPath = [(AppDelegate*)[UIApplication sharedApplication].delegate plistPath];
    NSMutableDictionary* plistDic = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    if([plistDic valueForKey:@"email"] && [plistDic valueForKey:@"password"]){
        [self resetModel];
    }else{
        [self unlinkToModel];
        TutorialController* loginCtr = [[TutorialController alloc] initWithNibName:@"TutorialView" bundle:nil];
        loginCtr.field=self;
        UINavigationController* navCtr = [[UINavigationController alloc] initWithRootViewController:loginCtr];
        navCtr.modalPresentationStyle=UIModalPresentationFormSheet;
        [self presentModalViewController:navCtr animated:YES];
    }
    [plistDic release];
    [layer setOrUpdateScene];    
}

-(void)viewDidDisappear:(BOOL)animated{
	CCDirector *director = [CCDirector sharedDirector];
    [director popScene];
    [director pause];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden=YES;
    glView = [[EAGLView viewWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) pixelFormat:kEAGLColorFormatRGB565 depthFormat:0] retain];
    glView.autoresizingMask=UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:glView];
    [self setView:glView];
    layer = [[DeskLayer alloc] initWithDelegate:self];
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

