#import "CoreDataManager.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "ThreadsManager.h"
#import "Deps.h"
#import "EmailAccountModel.h"

@interface CoreDataManager()
@property(nonatomic,retain) NSManagedObjectContext* mainContext;
@property(nonatomic,retain) NSManagedObjectContext* syncContext;
@end

@implementation CoreDataManager
@synthesize mainContext, syncContext;

-(id)init{
    if (self = [super init]){
        self.mainContext = [[[NSManagedObjectContext alloc] init] autorelease];
        [self.mainContext setStalenessInterval:0];
        [self.mainContext setPersistentStoreCoordinator: self.persistentStoreCoordinator];        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainContextDidSave:)
                                                    name:NSManagedObjectContextDidSaveNotification object:self.mainContext];
    }
    return self;
}

- (void)postInit {
    [[Deps sharedInstance].threadsManager performBlockOnBackgroundThread:^{
        self.syncContext = [[[NSManagedObjectContext alloc] init] autorelease];
        [self.syncContext setStalenessInterval:0];
        [self.syncContext setPersistentStoreCoordinator: self.persistentStoreCoordinator];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncContextDidSave:)
                                                     name:NSManagedObjectContextDidSaveNotification object:self.syncContext];
    } waitUntilDone:YES];

}

- (void)mainContextDidSave:(NSNotification*)notif {
    [[Deps sharedInstance].threadsManager performBlockOnBackgroundThread:^{
        NSArray *deletedObjects = [[notif userInfo] objectForKey:@"deleted"];
        for ( NSObject *obj in deletedObjects ) {
            if ([obj isKindOfClass:[EmailAccountModel class]]) {
                NSLog(@"MERGE DEL IN SYNC> %@", obj);
            }
        }
        deletedObjects = [[notif userInfo] objectForKey:@"inserted"];
        for ( NSObject *obj in deletedObjects ) {
            if ([obj isKindOfClass:[EmailAccountModel class]]) {
                NSLog(@"MERGE INS IN SYNC> %@", obj);
            }
        }
        [self.syncContext lock];
        [self.syncContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
        [self.syncContext mergeChangesFromContextDidSaveNotification:notif];
        [self.syncContext unlock];
    } waitUntilDone:NO];
}

- (void)syncContextDidSave:(NSNotification*)notif {
    [[Deps sharedInstance].threadsManager performBlockOnMainThread:^{
        NSArray *deletedObjects = [[notif userInfo] objectForKey:@"deleted"];
        for ( NSObject *obj in deletedObjects ) {
            if ([obj isKindOfClass:[EmailAccountModel class]]) {
                NSLog(@"MERGE DEL IN MAIN> %@", obj);
            }
        }
        deletedObjects = [[notif userInfo] objectForKey:@"inserted"];
        for ( NSObject *obj in deletedObjects ) {
            if ([obj isKindOfClass:[EmailAccountModel class]]) {
                NSLog(@"MERGE INS IN MAIN> %@", obj);
            }
        }
        [self.mainContext lock];
        [self.mainContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
        [self.mainContext mergeChangesFromContextDidSaveNotification:notif];
        [self.mainContext unlock];
    } waitUntilDone:NO];
}

-(void)dealloc{
    self.mainContext = nil;
    self.syncContext = nil;
    [managedObjectModel release];
    [persistentStoreCoordinator release];
    [super dealloc];
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
