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

#define APP_WILL_TERMINATE @"shouldSaveContext"
#define APP_DID_ENTER_BACKGROUND @"didEnterBackground"
@interface AppDelegate()
-(void)resetDatabase;
- (NSString *)databasePath;
- (NSManagedObjectModel *)managedObjectModel;
@property (nonatomic, retain) UINavigationController* navigationController;

@property(nonatomic,retain) NSManagedObjectContext* mainContext;
@property(nonatomic,retain) NSManagedObjectContext* syncContext;
@end

@implementation AppDelegate
@synthesize window,navigationController,mainContext,syncContext;

- (void) applicationDidFinishLaunching:(UIApplication*)application{
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

    
    
    self.mainContext = [[[NSManagedObjectContext alloc] init] autorelease];
    [self.mainContext setPersistentStoreCoordinator: self.persistentStoreCoordinator];
    self.syncContext = [[[NSManagedObjectContext alloc] init] autorelease];
    [self.syncContext setPersistentStoreCoordinator: self.persistentStoreCoordinator];
    
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
	[[CCDirector sharedDirector] end];
	[window release];
    [navigationController release];
    [managedObjectModel release];
    [persistentStoreCoordinator release];
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
        NSLog(@"ERROR %@",error);
    }
    
    return persistentStoreCoordinator;
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
