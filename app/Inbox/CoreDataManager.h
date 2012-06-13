#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
@interface CoreDataManager : NSObject{
    NSManagedObjectModel *managedObjectModel;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectContext* mainContext;
    NSManagedObjectContext* syncContext;
}
@property(readonly,nonatomic,retain) NSManagedObjectContext* mainContext;
@property(readonly,nonatomic,retain) NSManagedObjectContext* syncContext;
-(void)resetDatabase;
- (NSManagedObject *)objectFromId:(NSManagedObjectID *)objectID inContext:(NSManagedObjectContext *)context error:(NSError **)error;
- (void)postInit;
@end
