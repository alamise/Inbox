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
    NSDictionary* infos = [NSMutableDictionary dictionaryWithContentsOfFile:[self getPlistPath]];
    
    firstView = nil;
    
    if (!infos){
        infos = [[NSMutableDictionary alloc] init];
        [infos writeToFile:[self getPlistPath] atomically:YES];
        firstView = [[TutorialController alloc] initWithNibName:@"TutorialView" bundle:nil];
    }else{
        firstView = [[LoginController alloc] initWithNibName:@"LoginView" bundle:nil];
    }
    [application setStatusBarStyle:UIStatusBarStyleBlackOpaque];
	navigationController = [[UINavigationController alloc] initWithRootViewController:firstView];
	[window addSubview: navigationController.view];
	[window makeKeyAndVisible];
}

-(NSString*)getPlistPath{
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

-(NSManagedObjectContext*)getManagedObjectContext:(BOOL)reuse{
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
    NSManagedObjectContext *mainContext = [self getManagedObjectContext:YES];
    [mainContext mergeChangesFromContextDidSaveNotification:notification];  
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
        /*Error for store creation should be handled in here*/
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

	[super dealloc];
}

@end
