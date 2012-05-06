//
//  CoreDataManager.h
//  Inbox
//
//  Created by Simon Watiau on 5/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CoreDataManager : NSObject{
    NSManagedObjectModel *managedObjectModel;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectContext* mainContext;
    NSManagedObjectContext* syncContext;
}
@property(readonly,nonatomic,retain) NSManagedObjectContext* mainContext;
@property(readonly,nonatomic,retain) NSManagedObjectContext* syncContext;
-(void)resetDatabase;

@end
