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
@implementation BattlefieldController
@synthesize layer;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        NSString* plistPath = [(AppDelegate*)[UIApplication sharedApplication].delegate getPlistPath];
        NSMutableDictionary* plistDic = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
        model = [[BattlefieldModel alloc] initWithEmail:[plistDic valueForKey:@"email"] password:[plistDic valueForKey:@"password"]];
        model.delegate = self;
        
        [plistDic release];
	}
	return self;
}


- (void)dealloc {
    [model end];
    [model release];
    [super dealloc];
}


#pragma mark - rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    [self.layer didRotate];
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    [self.layer willRotate];
}

#pragma mark - view lifecycle

- (void)loadView {
    glView = [[EAGLView viewWithFrame:CGRectMake(0, 0, 100, 100) pixelFormat:kEAGLColorFormatRGB565 depthFormat:0] retain];
    [self setView:glView];
    self.layer = [BattlefieldLayer node];
    self.layer.delegate = self;
}

-(void)viewWillAppear:(BOOL)animated{
    CCDirector *director = [CCDirector sharedDirector];
    CCScene *scene = [CCScene node];
    [scene addChild:self.layer];
    [director setOpenGLView:glView];
    glClearColor(1, 1, 1, 1);
    if (director.runningScene){
        [director replaceScene:scene];
    }else{
        [director runWithScene:scene];
    }
    
}

-(void)loop{
    if ([model isDone]){
        [self.layer showDoneView];
    }else{
        NSString* nextWord = [model getNextWord];
        if (nextWord){
            [nextWord retain];
            isLoading = false;
            [self.layer putWord:nextWord];
            [nextWord release];
        }else{
            isLoading = true;
            [self.layer showLoadingView];
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

#pragma mark - view's lifecyle

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self loop];
    [self.layer didAppear];
}

-(void)viewDidDisappear:(BOOL)animated{
	CCDirector *director = [CCDirector sharedDirector];
    [director popScene];
    [model end];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden=FALSE;
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.layer = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}



@end

