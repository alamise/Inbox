//
//  AppDelegate.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/11/11.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
@class BattlefieldViewController;

@interface AppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow *window;
    UINavigationController* navigationController;

    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
}
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UINavigationController* navigationController;
-(NSString*)getPlistPath;
@end
