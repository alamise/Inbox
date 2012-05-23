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
#import "config.h"
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
#import "Deps.h"
#import "CoreDataManager.h"
#import "EmailReader.h"
#import "CTCoreAccount.h"
#import "EmailAccountModel.h"
#import "FolderModel.h"
#import "Synchronizer.h"
#import "PrivateValues.h"
#define MAX_ELEMENTS 5
@interface DeskController ()
@property(nonatomic,retain,readwrite) ModelsManager* modelsManager;
-(void)nextStep;
@end

@implementation DeskController
@synthesize modelsManager;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        isSyncing = true;
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(syncDone) name:SYNC_DONE object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(stateChanged) name:STATE_UPDATED object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(onError) name:SYNC_FAILED object:nil];
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

-(void)moveEmail:(EmailModel*)email toFolder:(FolderModel*)folder{// ya tout qui pete ici
    [[EmailReader sharedInstance] moveEmail:email toFolder:folder error:nil];
    [self performSelectorOnMainThread:@selector(nextStep) withObject:nil waitUntilDone:nil];
}

-(FolderModel*) archiveFolderForEmail:(EmailModel*)email{
    return [[EmailReader sharedInstance] archiveFolderForEmail:email error:nil];
}

-(void)archiveEmail:(EmailModel *)email{
    NSError* error;
    FolderModel* archiveFolder = [[EmailReader sharedInstance] archiveFolderForEmail:email error:&error];
    [[EmailReader sharedInstance] moveEmail:email toFolder:archiveFolder error:&error];
}

-(void)showEmail:(NSManagedObjectID*)emailId{
    EmailModel* email = (EmailModel*)[[[AppDelegate sharedInstance].coreDataManager mainContext] objectWithID:emailId];
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

-(void)fetchEmailBody:(EmailModel*)email{
    NSError* error = nil;
    [[EmailReader sharedInstance] fetchEmailBody:email error:&error];
    if (!error){
        [self performSelectorOnMainThread:@selector(showEmail:) withObject:email waitUntilDone:YES];
    }else{
        ErrorController* errorController = [[ErrorController alloc] initWithNibName:@"ErrorView" bundle:nil];
        errorController.actionOnDismiss = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(fetchEmailBody:) object:email] autorelease];
        UINavigationController* navCtr = [[UINavigationController alloc] initWithRootViewController:errorController];
        [navCtr.navigationBar setBarStyle:UIBarStyleBlack];
        navCtr.modalPresentationStyle=UIModalPresentationFormSheet;
        navCtr.modalTransitionStyle=UIModalTransitionStyleCoverVertical;
        [self presentModalViewController:navCtr animated:YES];
    }
}

-(void)showLoadingHud{
    if (loadingHud.alpha==0.0f){
        [loadingHud show:YES];    
    }
}

-(void)hideLoadingHud{
    [loadingHud hide:YES];
}

-(void)stateChanged{
    [self nextStep];
}

-(EmailModel*) lastEmailFromFolder:(FolderModel*)folder{
    return [[EmailReader sharedInstance] lastEmailFromFolder:folder exclude:nil read:YES error:nil];
}

-(void)nextStep{
    NSError* error;
    /* set the counter */
    int emailsInInbox = [[EmailReader sharedInstance] emailsCountInInboxes:&error];
    if (emailsInInbox > totalEmailsInThisSession){
        totalEmailsInThisSession = emailsInInbox;
    }
    int count = totalEmailsInThisSession - emailsInInbox;
    int total = totalEmailsInThisSession;
    
    float percentage= (float)100*count/total;

    [layer setPercentage:percentage labelCount:emailsInInbox];
    
    if ([layer elementsOnTheDesk] >= MAX_ELEMENTS){
        return;
    }
    
    EmailModel* nextEmail = [[EmailReader sharedInstance] lastEmailFromInboxExcluded:[layer mailsOnDesk] read:false error:&error];    
    
    if (nextEmail==nil){
        if (isSyncing){
            isWaiting = YES;
            [self performSelectorOnMainThread:@selector(showLoadingHud) withObject:nil waitUntilDone:YES];    
        }else{
            isWaiting = NO;
            [self performSelectorOnMainThread:@selector(hideLoadingHud) withObject:nil waitUntilDone:YES];
            // Inbox empty
        }
    }else{
        isWaiting = NO;
        [self performSelectorOnMainThread:@selector(hideLoadingHud) withObject:nil waitUntilDone:YES];
        [layer showFolders:[[EmailReader sharedInstance] foldersForAccount:nextEmail.folder.account error:&error]];
        
        [layer putEmail:nextEmail];
        if ([layer elementsOnTheDesk] < MAX_ELEMENTS){
            [self nextStep];
        }
    }
    
}

-(void)resetModel{

    NSManagedObjectContext* context = [[Deps sharedInstance].coreDataManager mainContext];
    [self.modelsManager abortSync];
    

    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailAccountModel entityName] inManagedObjectContext:context];
    request.entity = entity;
    NSError* fetchError = nil;
    NSArray* emailsModels = [context executeFetchRequest:request error:&fetchError];
    if (fetchError){
        return;
    }
    
    for (EmailAccountModel* account in emailsModels){
        [context deleteObject:account];
    }
    

    
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
    account.login = @"sim.w80@gmail.com";
    account.password = [[PrivateValues sharedInstance] myPassword]; // to test the sync
    NSError* error = nil;
    [context save:&error];
    if (error){
        NSLog(@"%@",error);
    }
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
    [layer refresh];
}

-(void)syncDone{
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [layer refresh];
    [self resetModel];
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

@end

