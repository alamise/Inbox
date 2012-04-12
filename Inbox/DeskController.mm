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
#import "models.h"
#import "cocos2d.h"
#import "InboxEmptyController.h"
#import "LoginController.h"
#import "Math.h"
#import "ModelsManager.h"
#import "EmailReader.h"
#import "CTCoreAccount.h"
#import "EmailAccountModel.h"
#import "FolderModel.h"
@interface DeskController ()
@property(nonatomic,retain,readwrite) ModelsManager* modelsManager;
-(void)nextStep;
@end

@implementation DeskController
@synthesize modelsManager;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        self.modelsManager = [[[ModelsManager alloc] init] autorelease];
        isSyncing = true;
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(syncDone) name:SYNC_DONE object:nil];
        [self.modelsManager startSync];
	}
	return self;
}

- (void)dealloc {
    self.modelsManager = nil;
    [layer release];
    [glView removeFromSuperview];
    [glView release];
    [super dealloc];
}

-(void)openSettings{
    LoginController* loginController = [[LoginController alloc] initWithNibName:@"LoginView" bundle:nil];
    loginController.actionOnDismiss = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(resetModel) object:nil] autorelease];
    UINavigationController* navCtr = [[UINavigationController alloc] initWithRootViewController:loginController];
    navCtr.modalPresentationStyle=UIModalPresentationFormSheet;
    navCtr.modalTransitionStyle=UIModalTransitionStyleCoverVertical;
    [self presentModalViewController:navCtr animated:YES];
}


-(void)moveEmail:(NSManagedObjectID*)emailId toFolder:(NSManagedObjectID*)folderId{
    [[EmailReader sharedInstance] moveEmail:emailId toFolder:folderId error:nil];
    [self performSelectorOnMainThread:@selector(nextStep) withObject:nil waitUntilDone:nil];
}

-(void)showEmail:(NSManagedObjectID*)emailId{
    EmailModel* email = (EmailModel*)[[(AppDelegate*)[UIApplication sharedApplication].delegate newManagedObjectContext] objectWithID:emailId];
    if (!email.htmlBody){
        [loadingHud showWhileExecuting:@selector(fetchEmailBody:) onTarget:self withObject:emailId animated:YES];    
    }else{
        EmailController* emailController = [[EmailController alloc] initWithEmail:emailId];
        UINavigationController* navCtr = [[UINavigationController alloc] initWithRootViewController:emailController];
        [navCtr.navigationBar setBarStyle:UIBarStyleBlack];
        navCtr.modalPresentationStyle=UIModalPresentationPageSheet;
        navCtr.modalTransitionStyle=UIModalTransitionStyleCoverVertical;
        [self presentModalViewController:navCtr animated:YES];
    }
}


-(void)emailTouched:(NSManagedObjectID*)emailId{
    [self performSelectorOnMainThread:@selector(showEmail:) withObject:emailId waitUntilDone:YES]; 
}

-(void)fetchEmailBody:(NSManagedObjectID*)emailId{
    NSError* error = nil;
    [[EmailReader sharedInstance] fetchEmailBody:emailId error:&error];
    if (!error){
        [self performSelectorOnMainThread:@selector(showEmail:) withObject:emailId waitUntilDone:YES];
    }else{
        ErrorController* errorController = [[ErrorController alloc] initWithNibName:@"ErrorView" bundle:nil];
        errorController.actionOnDismiss = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(fetchEmailBody:) object:emailId] autorelease];
        UINavigationController* navCtr = [[UINavigationController alloc] initWithRootViewController:errorController];
        [navCtr.navigationBar setBarStyle:UIBarStyleBlack];
        navCtr.modalPresentationStyle=UIModalPresentationFormSheet;
        navCtr.modalTransitionStyle=UIModalTransitionStyleCoverVertical;
        [self presentModalViewController:navCtr animated:YES];
    }
}


-(void)showLoadingHud{
    layer.isActive = NO;
    if (loadingHud.alpha==0.0f){
        [loadingHud show:YES];    
    }
}

-(void)hideLoadingHud{
    layer.isActive = YES;
    [loadingHud hide:YES];
}


#pragma mark model handlers

-(void)syncStarted{
    [self showLoadingHud];
    [self nextStep];
}

-(void)inboxChanged{
    [self nextStep];
}

-(void)syncDone{
    isSyncing =false;
    [self nextStep];
}

-(void)foldersReady{
    [self nextStep];
}

-(void)nextStep{
    NSError* error;
    int emailsInInbox = [[EmailReader sharedInstance] emailsCountInInboxes:&error];
    if (emailsInInbox>totalEmailsInThisSession){
        totalEmailsInThisSession = emailsInInbox;
    }
    int count = totalEmailsInThisSession-emailsInInbox;
    int total = totalEmailsInThisSession;
    
    float percentage= (float)100*count/total;
    // TODO find a logarithm like function to increase the counter faster at the beginning.
    [layer setPercentage:percentage labelCount:emailsInInbox];

    NSManagedObjectContext* context = [(AppDelegate*)[UIApplication sharedApplication].delegate newManagedObjectContext];    


    if ([layer mailsOnSceneCount]!=0) return;
    
    NSManagedObjectID* nextEmailId = [[EmailReader sharedInstance] lastEmailFromInbox:&error];    
    EmailModel* nextEmail = (EmailModel*)[context objectWithID:nextEmailId];
    
    if (![layer.folders isEqualToArray:[[EmailReader sharedInstance] foldersForAccount:nextEmail.folder.account.objectID error:&error]]){
        [layer foldersHidden:YES animated:YES];
        [layer setFolders:[[EmailReader sharedInstance] foldersForAccount:nextEmail.folder.account.objectID error:&error]];
        [layer foldersHidden:NO animated:YES];
    }
    
    [layer progressIndicatorHidden:FALSE animated:YES];
    [layer putEmail:nextEmail];
    
    
    if ([[EmailReader sharedInstance]emailsCountInInboxes:&error]==0){
        if (isSyncing){
            isWaiting = YES;
            [self performSelectorOnMainThread:@selector(showLoadingHud) withObject:nil waitUntilDone:YES];    
        }else{
            isWaiting = NO;
            [self performSelectorOnMainThread:@selector(hideLoadingHud) withObject:nil waitUntilDone:YES];

            InboxEmptyController* inboxEmptyController = [[InboxEmptyController alloc] initWithNibName:@"InboxEmptyView" bundle:nil];
            inboxEmptyController.actionOnDismiss = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(resetModel) object:nil] autorelease];
            
            UINavigationController* navCtr = [[UINavigationController alloc] initWithRootViewController:inboxEmptyController];
            [navCtr.navigationBar setBarStyle:UIBarStyleBlack];
            navCtr.modalPresentationStyle=UIModalPresentationFormSheet;
            navCtr.modalTransitionStyle=UIModalTransitionStyleCoverVertical;
            [self presentModalViewController:navCtr animated:YES];
        }
    }else{
        isWaiting = NO;
        [self performSelectorOnMainThread:@selector(hideLoadingHud) withObject:nil waitUntilDone:YES];
        NSManagedObjectID* nextEmailId = [[EmailReader sharedInstance] lastEmailFromInbox:&error];
        EmailModel* nextEmail = (EmailModel*)[[(AppDelegate*)[UIApplication sharedApplication].delegate newManagedObjectContext] objectWithID:nextEmailId];
        [layer putEmail:nextEmail];
    }
}

-(void)setNewModel{
}

-(void)resetModel{
    [(AppDelegate*)[UIApplication sharedApplication].delegate resetDatabase];
    NSManagedObjectContext* context = [(AppDelegate*)[UIApplication sharedApplication].delegate newManagedObjectContext];
    EmailAccountModel* account = nil;
    @try {
        account = [NSEntityDescription insertNewObjectForEntityForName:[EmailAccountModel entityName] inManagedObjectContext:context];
    }
    @catch (NSException *exception) {
        NSLog(@"mere");
    }
    [account retain];
    NSString* plistPath = [(AppDelegate*)[UIApplication sharedApplication].delegate plistPath];
    NSMutableDictionary* plistDic = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    account.serverAddr = @"imap.gmail.com";
    account.port = [NSNumber numberWithInt:993];
    account.conType = [NSNumber numberWithInt:CONNECTION_TYPE_TLS];
    account.authType = [NSNumber numberWithInt:IMAP_AUTH_TYPE_PLAIN];
    account.login = [plistDic objectForKey:@"login"];
    account.password = [plistDic objectForKey:@"password"];
    [context save:nil];
    [account release];
    [self.modelsManager startSync];
    [self nextStep];
}

-(void)onError{
    [self performSelectorOnMainThread:@selector(presentErrorView) withObject:nil waitUntilDone:NO];
}

-(void)presentErrorView{
    isSyncing = false;
    isWaiting = false;
    [self performSelectorOnMainThread:@selector(hideLoadingHud) withObject:nil waitUntilDone:YES];
    ErrorController* errorController = [[ErrorController alloc] initWithNibName:@"ErrorView" bundle:nil];
    errorController.actionOnDismiss = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(resetModel) object:nil] autorelease];
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
    [layer setOrUpdateScene];
    NSString* plistPath = [(AppDelegate*)[UIApplication sharedApplication].delegate plistPath];
    NSMutableDictionary* plistDic = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    if([plistDic valueForKey:@"email"] && [plistDic valueForKey:@"password"]){
        [self resetModel];
    }else{
        TutorialController* tutorialCtr = [[TutorialController alloc] initWithNibName:@"TutorialView" bundle:nil];
        tutorialCtr.actionOnDismiss = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(resetModel) object:nil] autorelease];
        UINavigationController* navCtr = [[UINavigationController alloc] initWithRootViewController:tutorialCtr];
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

