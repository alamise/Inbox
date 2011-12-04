//
//  AppDelegate.m
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/11/11.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//

#import "cocos2d.h"

#import "AppDelegate.h"
#import "GameConfig.h"
#import "BattlefieldController.h"
#import "BattlefieldLayer.h"
#import "CTCoreAccount.h"
#import "BattlefieldModel.h"
#import "LoginController.h"
#import "TutorialController.h"
@implementation AppDelegate
@synthesize window,navigationController;

- (void) applicationDidFinishLaunching:(UIApplication*)application{
    if (![CCDirector setDirectorType:kCCDirectorTypeDisplayLink])
        [CCDirector setDirectorType:kCCDirectorTypeDefault];

    CCDirector *director = [CCDirector sharedDirector];
    [director setAnimationInterval:1.0/60];
    [director setDisplayFPS:YES];
    [CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA8888];
    [director setDeviceOrientation:kCCDeviceOrientationPortrait];
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    UIViewController* firstView = nil;
    NSDictionary* infos = [NSMutableDictionary dictionaryWithContentsOfFile:[self getPlistPath]];
    
    firstView = [[LoginController alloc] init];
    
    if (!infos){
        infos = [[NSMutableDictionary alloc] init];
        [infos writeToFile:[self getPlistPath] atomically:YES];
        firstView = [[TutorialController alloc] initWithNibName:@"TutorialView" bundle:nil];
    }else{
        firstView = [[LoginController alloc] init];
    }
    
	navigationController = [[UINavigationController alloc] initWithRootViewController:firstView];
	[window addSubview: navigationController.view];
	[window makeKeyAndVisible];
}

-(NSString*)getPlistPath{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"infos.plist"];
}

- (void)applicationWillResignActive:(UIApplication *)application {
	[[CCDirector sharedDirector] pause];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	[[CCDirector sharedDirector] resume];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	[[CCDirector sharedDirector] purgeCachedData];
}

-(void) applicationDidEnterBackground:(UIApplication*)application {
	[[CCDirector sharedDirector] stopAnimation];
}

-(void) applicationWillEnterForeground:(UIApplication*)application {
	[[CCDirector sharedDirector] startAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	CCDirector *director = [CCDirector sharedDirector];
	[[director openGLView] removeFromSuperview];	
    [director end];	
	[window release];
	[navigationController release];
}

- (void)applicationSignificantTimeChange:(UIApplication *)application {
	[[CCDirector sharedDirector] setNextDeltaTimeZero:YES];
}

- (void)dealloc {
	[[CCDirector sharedDirector] end];
	[window release];
    [navigationController release];
	[super dealloc];
}

@end
