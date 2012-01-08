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
#import "CrashController.h"

@interface AppDelegate()
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, retain) UINavigationController* navigationController;
@end

@implementation AppDelegate
@synthesize window,navigationController,managedObjectContext,managedObjectModel;

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
    NSDictionary* infos = [NSMutableDictionary dictionaryWithContentsOfFile:[self plistPath]];
    
    firstView = nil;
    
    if (!infos){
        infos = [[NSMutableDictionary alloc] init];
        [infos writeToFile:[self plistPath] atomically:YES];
        [infos release];
        firstView = [[TutorialController alloc] initWithNibName:@"TutorialView" bundle:nil];
    }else{
        firstView = [[LoginController alloc] initWithNibName:@"LoginView" bundle:nil];
    }
    firstView = [[DeskController alloc] init];
    [application setStatusBarStyle:UIStatusBarStyleBlackOpaque];
	navigationController = [[UINavigationController alloc] initWithRootViewController:firstView];
	[window addSubview: navigationController.view];
    
    crashController = [[CrashController sharedInstance] retain];
    crashController.delegate = self;
    
    [crashController sendCrashReportsToEmail:@"sim.w80+inbox@gmail.com" withViewController:navigationController];
	[window makeKeyAndVisible];
}

- (void)onCrash{
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


#pragma mark - CoreData

-(NSManagedObjectContext*)managedObjectContext:(BOOL)reuse{
    if (managedObjectContext != nil && reuse) {
        return managedObjectContext;
    }
    NSManagedObjectContext* context;
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        context = [[NSManagedObjectContext alloc] init];
        [context setPersistentStoreCoordinator: coordinator];
    }
    
    if (!managedObjectContext){
        managedObjectContext = [context retain];
        return managedObjectContext;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mergeChangesWithMainContext:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:context];
    

    return [context autorelease];
}

- (void)mergeChangesWithMainContext:(NSNotification *)notification{
    NSManagedObjectContext *mainContext = [self managedObjectContext:YES];
    [mainContext mergeChangesFromContextDidSaveNotification:notification];  
}

- (NSManagedObjectModel *)managedObjectModel {
    @synchronized(managedObjectContext) {
        if (managedObjectModel != nil) {
            return managedObjectModel;
        }
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"coreDataSchema" withExtension:@"momd"];
        managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        
        return managedObjectModel;
    }
}

- (NSString *)databasePath {
    NSString* path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return [path stringByAppendingPathComponent: @"coredata.sqlite"];
}

-(void)resetDatabase{
    @synchronized(managedObjectContext) {
        if (!persistentStoreCoordinator){
            return;
        }
        [managedObjectContext release];
        managedObjectContext = nil;
        
        NSArray *stores = [persistentStoreCoordinator persistentStores];
        for(NSPersistentStore *store in stores) {
            [persistentStoreCoordinator removePersistentStore:store error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:store.URL.path error:nil];
        }
        [persistentStoreCoordinator release];
        persistentStoreCoordinator = nil;
    }
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
    NSURL *storeUrl = [NSURL fileURLWithPath: [self databasePath]];
    NSError *error = nil;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
                                  initWithManagedObjectModel:[self managedObjectModel]];
    if(![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                 configuration:nil URL:storeUrl options:nil error:&error]) {
        NSLog(@"pers %@",[error localizedDescription]);
    }
    return persistentStoreCoordinator;

}


- (void)dealloc {
	[[CCDirector sharedDirector] end];
	[window release];
    [navigationController release];
    [managedObjectContext release];
    [managedObjectModel release];
    [persistentStoreCoordinator release];
    [crashController release];
	[super dealloc];
}

@end
