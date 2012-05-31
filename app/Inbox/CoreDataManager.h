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
- (void)postInit;
@end
