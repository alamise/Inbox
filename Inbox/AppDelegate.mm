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
#import "GameConfig.h"
#import "DeskController.h"
#import "DeskLayer.h"
#import "CTCoreAccount.h"
#import "GmailModel.h"
#import "LoginController.h"
#import "TutorialController.h"
#import "GmailModel.h"
#import "Logger.h"
#import "DDTTYLogger.h"
#import "GANTracker.h"
#import "BWQuincyManager.h"
#import "FlurryAnalytics.h"

#define APP_WILL_TERMINATE @"shouldSaveContext"
#define APP_DID_ENTER_BACKGROUND @"didEnterBackground"
@interface AppDelegate()
-(void)resetDatabase;
- (NSString *)databasePath;
- (NSManagedObjectModel *)managedObjectModel;
@property (nonatomic, retain) UINavigationController* navigationController;
@end

@implementation AppDelegate
@synthesize window,navigationController;

- (void) applicationDidFinishLaunching:(UIApplication*)application{
    if (![CCDirector setDirectorType:kCCDirectorTypeDisplayLink])
        [CCDirector setDirectorType:kCCDirectorTypeDefault];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(asyncActivityStarted) name:MODEL_ACTIVE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(asyncActivityEnded) name:MODEL_UNACTIVE object:nil];

    CCDirector *director = [CCDirector sharedDirector];
    [director setAnimationInterval:1.0/60];
    [director setDisplayFPS:YES];
    [CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA8888];
    [director setDeviceOrientation:kCCDeviceOrientationPortrait];
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    [application setStatusBarStyle:UIStatusBarStyleBlackOpaque];
	navigationController = [[UINavigationController alloc] initWithRootViewController:[[[DeskController alloc] init] autorelease]];
	[window addSubview: navigationController.view];
    
    [[GANTracker sharedTracker] startTrackerWithAccountID:@"UA-30673935-1"
                                           dispatchPeriod:10
                                                 delegate:nil];

    
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [[GANTracker sharedTracker] trackPageview:@"/app_started" withError:nil];
    [FlurryAnalytics logEvent:@"app_started" timed:NO];
    [[BWQuincyManager sharedQuincyManager] setSubmissionURL:@"http://yourserver.com/crash_v200.php"];
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    [FlurryAnalytics startSession:@"P6ZVR2Y2BH45WPL41EIK"];
 
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
    [[GANTracker sharedTracker] stopTracker];
	[[CCDirector sharedDirector] end];
	[window release];
    [navigationController release];
    [managedObjectModel release];
    [persistentStoreCoordinator release];
	[super dealloc];
}

- (void)onCrash{
    DDLogError(@"AppDelegate:onCrash:crashHandler: The app crashed");
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Crash"
                                                    message:@"The App has crashed and will attempt to send a crash report"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

-(NSString*)plistPath{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:APP_DID_ENTER_BACKGROUND object:nil];
}

-(void) applicationWillEnterForeground:(UIApplication*)application {
	[[CCDirector sharedDirector] startAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application {
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

#pragma mark - CoreData


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
    NSURL *storeUrl = [NSURL fileURLWithPath: [self databasePath]];
    NSError *error = nil;
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];

    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
                                  initWithManagedObjectModel:[self managedObjectModel]];
    if(![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                 configuration:nil URL:storeUrl options:options error:&error]) {
        // TODO
    }
    
    return persistentStoreCoordinator;
}


-(NSManagedObjectContext*)newManagedObjectContext{
    @synchronized(self){
        NSManagedObjectContext* context;
        context = [[[NSManagedObjectContext alloc] init] autorelease];
        [context setPersistentStoreCoordinator: self.persistentStoreCoordinator];
        return context;
    }
}

- (NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"coreDataSchema" withExtension:@"momd"];
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    return managedObjectModel;
}

- (NSString *)databasePath {
    NSString* path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return [path stringByAppendingPathComponent: @"coredata.sqlite"];
}

-(void)resetDatabase{
    if (!persistentStoreCoordinator){
        return;
    }
    NSArray *stores = [persistentStoreCoordinator persistentStores];
    for(NSPersistentStore *store in stores) {
        [persistentStoreCoordinator removePersistentStore:store error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:store.URL.path error:nil];
    }
    [persistentStoreCoordinator release];
    persistentStoreCoordinator = nil;
    [managedObjectModel release];
    managedObjectModel = nil;
}

@end
