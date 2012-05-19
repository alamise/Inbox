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

#import "cocos2d.h"

#import "AppDelegate.h"
#import "config.h"
#import "DeskController.h"
#import "DeskLayer.h"
#import "CTCoreAccount.h"
#import "models.h"
#import "LoginController.h"
#import "TutorialController.h"
#import "models.h"
#import "Logger.h"
#import "DDTTYLogger.h"
#import "BWQuincyManager.h"
#import "FlurryAnalytics.h"
#import "PrivateValues.h"
#import "BackgroundThread.h"

#define APP_WILL_TERMINATE @"shouldSaveContext"
#define APP_DID_ENTER_BACKGROUND @"didEnterBackground"
@interface AppDelegate()
@property (nonatomic, retain) UINavigationController* navigationController;
@property(nonatomic,retain,readwrite) CoreDataManager* coreDataManager;
@property(nonatomic,retain,readwrite) BackgroundThread* backgroundThread;
@end

@implementation AppDelegate
@synthesize window, navigationController, coreDataManager, backgroundThread;

- (void) applicationDidFinishLaunching:(UIApplication*)application{
    self.backgroundThread = [[[BackgroundThread alloc] init] autorelease];
    [self.backgroundThread.thread start];
    
    self.coreDataManager = [[[CoreDataManager alloc] init] autorelease];
    
    if (![CCDirector setDirectorType:kCCDirectorTypeDisplayLink])
        [CCDirector setDirectorType:kCCDirectorTypeDefault];

    CCDirector *director = [CCDirector sharedDirector];
    [director setAnimationInterval:1.0/60];
    [director setDisplayFPS:YES];
    [CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA8888];
    [director setDeviceOrientation:kCCDeviceOrientationPortrait];
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    [application setStatusBarStyle:UIStatusBarStyleBlackOpaque];
	navigationController = [[UINavigationController alloc] initWithRootViewController:[[[DeskController alloc] init] autorelease]];
	[window addSubview: navigationController.view];    
    [DDLog addLogger:[DDTTYLogger sharedInstance]];

    [FlurryAnalytics startSession:[[PrivateValues sharedInstance]flurryApiKey]];
    //[[BWQuincyManager sharedQuincyManager] setSubmissionURL:[[PrivateValues sharedInstance] quincyServer]];
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    [FlurryAnalytics logEvent:@"app in use" timed:YES];
	[window makeKeyAndVisible];
}

void uncaughtExceptionHandler(NSException *exception) {
    [FlurryAnalytics logError:@"Uncaught" message:@"Crash!" exception:exception];
}

-(void) asyncActivityStarted{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];   
}

-(void) asyncActivityEnded{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];    
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

-(NSString*)plistPath{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return [documentsDirectory stringByAppendingPathComponent:@"infos.plist"];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [FlurryAnalytics endTimedEvent:@"app in use" withParameters:nil];
	[[CCDirector sharedDirector] pause];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FlurryAnalytics logEvent:@"app in use" timed:YES];
	[[CCDirector sharedDirector] resume];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	[[CCDirector sharedDirector] purgeCachedData];
}

-(void) applicationDidEnterBackground:(UIApplication*)application {
    [FlurryAnalytics endTimedEvent:@"app in use" withParameters:nil];
	[[CCDirector sharedDirector] stopAnimation];
    [[NSNotificationCenter defaultCenter] postNotificationName:APP_DID_ENTER_BACKGROUND object:nil];
}

-(void) applicationWillEnterForeground:(UIApplication*)application {
    [FlurryAnalytics logEvent:@"app in use" timed:YES];
	[[CCDirector sharedDirector] startAnimation];
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

+(AppDelegate*)sharedInstance {
    return (AppDelegate*)[UIApplication sharedApplication].delegate;
}

@end
