//
//  RootViewController.m
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/11/11.
//



#import "BattlefieldViewController.h"
#import "GameConfig.h"
#import "AppDelegate.h"
#import "BattlefieldLayer.h"
#import "Plop.h"
@implementation BattlefieldViewController
@synthesize layer;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
	}
	return self;
}

- (void)loadView {
    CCDirector *director = [CCDirector sharedDirector];
    [director setDeviceOrientation:kCCDeviceOrientationPortrait];
    EAGLView *glView = [EAGLView viewWithFrame:CGRectMake(0, 0, 100, 100) pixelFormat:kEAGLColorFormatRGB565 depthFormat:0];
    [director setOpenGLView:glView];
    self.layer = [BattlefieldLayer node];
    CCScene *scene = [CCScene node];
    [scene addChild:self.layer];
    [director runWithScene: scene];
    [self setView:glView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden=FALSE;
    Plop* plop = [[Plop alloc] initWithNibName:@"Plop" bundle:nil];
    [self.navigationController pushViewController:plop animated:YES];
}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.layer redraw];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    [self.layer redraw];
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.layer = nil;
}

- (void)dealloc {
    [super dealloc];
}


@end

