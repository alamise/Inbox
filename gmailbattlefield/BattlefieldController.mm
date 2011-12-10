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
@implementation BattlefieldController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        NSString* plistPath = [(AppDelegate*)[UIApplication sharedApplication].delegate getPlistPath];
        NSMutableDictionary* plistDic = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
        model = [[BattlefieldModel alloc] initWithEmail:[plistDic valueForKey:@"email"] password:[plistDic valueForKey:@"password"]];
        model.delegate = self;
        [model startProcessing];
        [plistDic release];
	}
	return self;
}

- (void)dealloc {
    [model end];
    [model release];
    [layer release];
    [glView removeFromSuperview];
    [glView release];
    [super dealloc];
}

-(void)loop{
    if ([model isDone]){
        [layer showDoneView];
    }else{
        NSString* nextWord = [model getNextWord];
        if (nextWord){
            [nextWord retain];
            isLoading = false;
            [layer putWord:nextWord];
            [nextWord release];
            [loadingHud hide:true];
        }else{
            isLoading = true;
            [loadingHud show:true];
        }
    }
}

- (void)nextWordReady{
    if (isLoading){
        [self loop];
    }
}

-(void)sortedWord:(NSString*)word isGood:(BOOL)isGood{
    [model sortedWord:word isGood:isGood];
    [self loop];
}


#pragma mark - rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    [layer didRotate];
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    [layer willRotate];
}

#pragma mark - view lifecycle

-(void)viewWillAppear:(BOOL)animated{
    CCDirector *director = [CCDirector sharedDirector];
    CCScene *scene = [CCScene node];
    [scene addChild:layer];
    [director setOpenGLView:glView];
    glClearColor(0.93, 0.93, 0.93, 1);
    if (director.runningScene){
        [director replaceScene:scene];
    }else{
        [director runWithScene:scene];
    }
}

-(void)onError:(NSString*)errorMessage{
  }

#pragma mark - view's lifecyle

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self loop];
    [layer didAppear];
}

-(void)viewDidDisappear:(BOOL)animated{
	CCDirector *director = [CCDirector sharedDirector];
    [director popScene];
    [model end];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden=FALSE;

    glView = [[EAGLView viewWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) pixelFormat:kEAGLColorFormatRGB565 depthFormat:0] retain];
    [self.view addSubview:glView];
    [self setView:glView];
    layer = [[BattlefieldLayer node] retain];
    layer.delegate = self;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
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

