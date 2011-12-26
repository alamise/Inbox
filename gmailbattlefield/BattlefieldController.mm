//
//  RootViewController.m
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/11/11.
//

#import "BattlefieldController.h"
#import "GameConfig.h"
#import "AppDelegate.h"
#import "BattlefieldLayer.h"
#import "MBProgressHUD.h"
#import "EmailController.h"
#import "TutorialController.h"
#import "ErrorController.h"

@interface BattlefieldController ()
@property(nonatomic,retain)BattlefieldModel* model;
@end
@implementation BattlefieldController
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
        // show done view
    }else{
        [layer putEmail:[model getLastEmailFrom:@"INBOX"]];
    }
}

-(void)syncDone{
    [loadingHud hide:true];
    [self nextStep];
}



-(void)move:(EmailModel*)m to:(NSString*)folder{
    [model move:m to:folder];
    [self nextStep];
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

#pragma mark - view lifecycle


-(void)onError:(NSString*)errorMessage{
    ErrorController* errorController = [[ErrorController alloc] initWithNibName:@"ErrorView" bundle:nil];
    errorController.field = self;
    UINavigationController* navigationController = [[[UINavigationController alloc] initWithRootViewController:errorController] autorelease];
    [errorController release];
    navigationController.modalPresentationStyle=UIModalPresentationFormSheet;
    [self presentModalViewController:navigationController animated:YES];
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
    NSString* plistPath = [(AppDelegate*)[UIApplication sharedApplication].delegate getPlistPath];
    NSMutableDictionary* plistDic = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    if([plistDic valueForKey:@"email"] && [plistDic valueForKey:@"password"]){
        self.model = [[BattlefieldModel alloc] initWithAccount:[plistDic valueForKey:@"email"] password:[plistDic valueForKey:@"password"] delegate:self];
        [model sync];        
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

-(void)reload{
    NSString* plistPath = [(AppDelegate*)[UIApplication sharedApplication].delegate getPlistPath];
    NSMutableDictionary* plistDic = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];

    self.model = [[BattlefieldModel alloc] initWithAccount:[plistDic valueForKey:@"email"] password:[plistDic valueForKey:@"password"] delegate:self];
    
    [model performSelector:@selector(sync) withObject:nil afterDelay:1];
    [plistDic release];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    glView = [[EAGLView viewWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) pixelFormat:kEAGLColorFormatRGB565 depthFormat:0] retain];
    glView.autoresizingMask=UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:glView];
    [self setView:glView];
    layer = [[[BattlefieldLayer alloc] initWithDelegate:self] retain];
    loadingHud = [[MBProgressHUD alloc] initWithFrame:self.view.frame];
    loadingHud.labelText = NSLocalizedString(@"field.loading.title",@"Loading title used in the loading HUD of the field");
    loadingHud.detailsLabelText = NSLocalizedString(@"field.loading.message",@"Loading message used in the loading HUD of the field");
    [self.view addSubview:loadingHud];
    [loadingHud show:YES];

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

