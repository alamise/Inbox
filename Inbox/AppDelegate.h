//
//  AppDelegate.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/11/11.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#define IS_IPAD true
@class BattlefieldViewController;

@interface AppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow *window;
    UINavigationController* navigationController;

    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
}
@property (nonatomic, retain,readwrite) UIWindow *window;
-(NSString*)getPlistPath;

-(NSManagedObjectContext*)getManagedObjectContext:(BOOL)reuse;
@end
