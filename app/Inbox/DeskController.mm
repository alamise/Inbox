#import "DeskController.h"
#import "config.h"
#import "AppDelegate.h"
#import "DeskLayer.h"
#import "MBProgressHUD.h"
#import "EmailController.h"
#import "ErrorController.h"
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
#import "SynchroManager.h"
#import "ThreadsManager.h"

#define MAX_ELEMENTS 5
@interface DeskController ()
@property(nonatomic,retain,readwrite) ModelsManager *modelsManager;
-(void)nextStep;
@end

@implementation DeskController
@synthesize modelsManager;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncDone) name:SYNC_DONE object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stateChanged) name:STATE_UPDATED object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onError) name:SYNC_FAILED object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSyncReloaded) name:SYNC_RELOADED object:nil];
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


- (void)showEmail:(NSManagedObjectID *)emailId {
    EmailModel* email = (EmailModel*)[[[Deps sharedInstance].coreDataManager mainContext] objectWithID:emailId];
    if (!email.htmlBody){
        [loadingHud showWhileExecuting:@selector(fetchEmailBody:) onTarget:self withObject:emailId animated:YES];    
    }else{
        EmailController* emailController = [[EmailController alloc] initWithEmail:emailId];
        [self presentInNavigationController:emailController];
        [emailController release];
    }
}

- (void)fetchEmailBody:(EmailModel*)email {
    NSError* error = nil;
    [[EmailReader sharedInstance] fetchEmailBody:email error:&error];
    if (!error){
        [self performSelectorOnMainThread:@selector(showEmail:) withObject:email waitUntilDone:YES];
    }else{
        ErrorController* errorController = [[ErrorController alloc] initWithNibName:@"ErrorView" bundle:nil];
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

#pragma mark update everything

- (void)updateCounterWithError:(NSError **)error {
    *error = nil;
    int emailsInInbox = [[EmailReader sharedInstance] emailsCountInInboxes:error];
    if (*error) {
        [layer setPercentage:0 labelCount:-1];
        return;
    }
    if (emailsInInbox > totalEmailsInThisSession){
        totalEmailsInThisSession = emailsInInbox;
    }
    int count = totalEmailsInThisSession - emailsInInbox;
    int total = totalEmailsInThisSession;
    
    float percentage= (float)100*count/total;
    
    [layer setPercentage:percentage labelCount:emailsInInbox];
}

- (void)nextStep {
    NSError* error = nil;

    [self updateCounterWithError:&error];
    if ( error ) {
        [self putInErrorState];
        return;
    }
    
    if ([layer elementsOnTheDesk] >= MAX_ELEMENTS){
        return;
    }
    
    EmailModel* nextEmail = [[EmailReader sharedInstance] lastEmailFromInboxExcluded:[layer mailsOnDesk] read:true error:&error];    
    
    if ( error ) {
        [self putInErrorState];
        return;
    }
    
    if ( nextEmail == nil ) {
        if ([[Deps sharedInstance].synchroManager isSyncing]) {
            isWaiting = YES;
            [self showLoadingHud];
            
        } else {
            isWaiting = NO;
            [self hideLoadingHud];
            // Inbox empty
        }
    } else {
        isWaiting = NO;
        [self hideLoadingHud];
        [layer showFolders:[[EmailReader sharedInstance] foldersForAccount:nextEmail.folder.account error:&error]];
        
        [layer putEmail:nextEmail];
        if ([layer elementsOnTheDesk] < MAX_ELEMENTS){
            [self nextStep];
        }
    }    
}

- (void)onSyncReloaded{
    [layer cleanDesk];
    [self startSyncIfNeeded];
}

-(void)onError {
    [self putInErrorState];
}

-(void)syncDone{
}

#pragma mark display views

/*
 * Stop the synchro and present the error view
 */
- (void)putInErrorState {
    isWaiting = false;
    [self hideLoadingHud];
    ErrorController* errorController = [[ErrorController alloc] initWithRetryBlock:^{
        [self startSyncIfNeeded];
    }];
    [self presentInNavigationController: errorController];
    [errorController release];
}

- (void)startSyncIfNeeded {
    if ( ![[Deps sharedInstance].synchroManager isSyncing] ) {
        [[Deps sharedInstance].synchroManager startSync];
    }
    [self nextStep];
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
    UIButton *b = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    b.frame = CGRectMake(400, 20, 40, 40);
    [b addTarget:self action:@selector(theMagicButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:b];
}

- (void)theMagicButtonAction {

}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [layer refresh];
}

-(void)viewDidDisappear:(BOOL)animated{
	CCDirector *director = [CCDirector sharedDirector];
    [director popScene];
    [director pause];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
    glView = [[EAGLView viewWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) pixelFormat:kEAGLColorFormatRGB565 depthFormat:0] retain];
    glView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:glView];
    [self setView:glView];
    layer = [[DeskLayer alloc] initWithDelegate:self];
    loadingHud = [[MBProgressHUD alloc] initWithFrame:self.view.frame];
    loadingHud.labelText = NSLocalizedString(@"desk.loadinghud.title",@"");
    loadingHud.detailsLabelText = NSLocalizedString(@"desk.loadinghud.message",@"");
    [self.view addSubview:loadingHud];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [layer release];
    [glView removeFromSuperview];
    [glView release];
    [loadingHud release];
}

- (void)presentInNavigationController:(UIViewController *)controller {
    UINavigationController* navCtr = [[UINavigationController alloc] initWithRootViewController:controller];
    navCtr.modalPresentationStyle = UIModalPresentationFormSheet;
    navCtr.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentModalViewController:navCtr animated:YES];
    [navCtr release];
}

#pragma mark desk protocol implementation

- (void)emailTouched:(NSManagedObjectID *)emailId{
    [self performSelectorOnMainThread:@selector(showEmail:) withObject:emailId waitUntilDone:YES]; 
}

- (EmailModel*) lastEmailFromFolder:(FolderModel *)folder {
    return [[EmailReader sharedInstance] lastEmailFromFolder:folder exclude:nil read:YES error:nil];
}

- (void)openSettings {
    LoginController* loginController = [[LoginController alloc] initWithNibName:@"LoginView" bundle:nil];
    [self presentInNavigationController:loginController];
    [loginController release];
}

- (void)moveEmail:(EmailModel *)email toFolder:(FolderModel *)folder {
    NSError *error = nil;
    [[EmailReader sharedInstance] moveEmail:email toFolder:folder error:&error];
    if ( error ) {
        DDLogVerbose( @"Error when moving the email %@",email.subject );
    }
    if (![[Deps sharedInstance].synchroManager isSyncing]) {
        [[Deps sharedInstance].synchroManager startSync];
    }
    [self nextStep];
}

- (FolderModel*)archiveFolderForEmail:(EmailModel*)email {
    return [[EmailReader sharedInstance] archiveFolderForEmail:email error:nil];
}

-(void)archiveEmail:(EmailModel *)email {
    NSError* error = nil;
    FolderModel* archiveFolder = [[EmailReader sharedInstance] archiveFolderForEmail:email error:&error];
    [[EmailReader sharedInstance] moveEmail:email toFolder:archiveFolder error:&error];
}

@end

