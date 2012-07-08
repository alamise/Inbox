#import "cocos2d.h"
#import "AppDelegate.h"
#import "config.h"
#import "DeskController.h"
#import "DeskLayer.h"
#import "CTCoreAccount.h"
#import "LoginController.h"
#import "Logger.h"
#import "DDTTYLogger.h"
#import "BWQuincyManager.h"
#import "FlurryAnalytics.h"
#import "PrivateValues.h"
#import "ThreadsManager.h"
#import "Deps.h"
#import "SynchroManager.h"
#import "config.h"
#define APP_WILL_TERMINATE @"shouldSaveContext"
#define APP_DID_ENTER_BACKGROUND @"didEnterBackground"

@interface AppDelegate ()

@property(nonatomic, retain) UINavigationController *navigationController;
@property(nonatomic, retain, readwrite) CoreDataManager *coreDataManager;
@property(nonatomic, retain, readwrite) BackgroundThread *backgroundThread;

@end

@implementation AppDelegate
@synthesize window, navigationController, coreDataManager, backgroundThread;

- (void)applicationDidFinishLaunching:(UIApplication*)application {
    [application setStatusBarStyle:UIStatusBarStyleBlackOpaque];
    [self setupDirector];
	[self setupWindow];
    [FlurryAnalytics logEvent:@"app in use" timed:YES];
}

#pragma mark - setup method

-(void)setupLogger {
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    #ifndef DEBUG
        [FlurryAnalytics startSession:[[PrivateValues sharedInstance]flurryApiKey]];
        [[BWQuincyManager sharedQuincyManager] setSubmissionURL:[[PrivateValues sharedInstance] quincyServer]];
        NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    #endif
}

- (void)setupDirector {
    if ( ![CCDirector setDirectorType:kCCDirectorTypeDisplayLink] ) {
        [CCDirector setDirectorType:kCCDirectorTypeDefault];
    }
    CCDirector *director = [CCDirector sharedDirector];
    [director setAnimationInterval:1.0/60];
    [director setDisplayFPS:YES];
    [CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA8888];
    [director setDeviceOrientation:kCCDeviceOrientationPortrait];
}

- (void)setupWindow {
    window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	navigationController = [[UINavigationController alloc] initWithRootViewController:[Deps sharedInstance].deskController];
	[window addSubview: navigationController.view];    
    [window makeKeyAndVisible];
}

- (void)startSync {
    if ( ![[Deps sharedInstance].synchroManager isSyncing] ) {
        [[Deps sharedInstance].synchroManager startSync];
    }
}

#ifndef DEBUG
    void uncaughtExceptionHandler(NSException *exception) {
        [FlurryAnalytics logError:@"Uncaught" message:@"Crash!" exception:exception];
    }
#endif

- (void)asyncActivityStarted {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)asyncActivityEnded {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (NSString *)plistPath {
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return [documentsDirectory stringByAppendingPathComponent:@"infos.plist"];
}

+ (AppDelegate *)sharedInstance {
    return (AppDelegate*)[UIApplication sharedApplication].delegate;
}

#pragma mark - ApplicationDelegate's methods

- (void)applicationWillResignActive:(UIApplication *)application {
    [FlurryAnalytics endTimedEvent:@"app in use" withParameters:nil];
    [[CCDirector sharedDirector] pause];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FlurryAnalytics logEvent:@"app in use" timed:YES];
	[[CCDirector sharedDirector] resume];
    [self startSync];
}

-(void) applicationDidEnterBackground:(UIApplication *)application {
    [FlurryAnalytics endTimedEvent:@"app in use" withParameters:nil];
    [[CCDirector sharedDirector] stopAnimation];
    [[NSNotificationCenter defaultCenter] postNotificationName:APP_DID_ENTER_BACKGROUND object:nil];
}

-(void) applicationWillEnterForeground:(UIApplication*)application {
    [FlurryAnalytics logEvent:@"app in use" timed:YES];
    [[CCDirector sharedDirector] startAnimation];
    [self startSync];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [FlurryAnalytics endTimedEvent:@"app in use" withParameters:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:APP_WILL_TERMINATE object:nil];
    CCDirector *director = [CCDirector sharedDirector];
    [[director openGLView] removeFromSuperview];	
    [director end];	
    [window release];
    [navigationController release];
}

- (void)applicationSignificantTimeChange:(UIApplication *)application {
    [[CCDirector sharedDirector] setNextDeltaTimeZero:YES];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    [[CCDirector sharedDirector] purgeCachedData];
}

- (void)dealloc {
    self.coreDataManager = nil;
    [[CCDirector sharedDirector] end];
    [window release];
    [navigationController release];
    [self.backgroundThread stop];
    self.backgroundThread = nil;
    [super dealloc];
}

@end
