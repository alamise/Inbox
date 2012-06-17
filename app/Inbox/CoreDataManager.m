#import "CoreDataManager.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "ThreadsManager.h"
#import "Deps.h"
#import "EmailAccountModel.h"
#import "errorCodes.h"

@interface CoreDataManager()
@property(nonatomic,retain) NSManagedObjectContext* mainContext;
@property(nonatomic,retain) NSManagedObjectContext* syncContext;
@end

@implementation CoreDataManager
@synthesize mainContext, syncContext;

- (id)init {
    if ( self = [super init] ) {
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

- (void)mainContextDidSave:(NSNotification *)notif {
    [[Deps sharedInstance].threadsManager performBlockOnBackgroundThread:^{
        [self.syncContext lock];
        [self.syncContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
        [self.syncContext mergeChangesFromContextDidSaveNotification:notif];
        [self.syncContext unlock];
    } waitUntilDone:NO];
}

- (void)syncContextDidSave:(NSNotification *)notif {
    [[Deps sharedInstance].threadsManager performBlockOnMainThread:^{
        [self.mainContext lock];
        [self.mainContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
        [self.mainContext mergeChangesFromContextDidSaveNotification:notif];
        [self.mainContext unlock];
    } waitUntilDone:NO];
}

- (void)dealloc {
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


- (NSManagedObject *)objectFromId:(NSManagedObjectID *)objectID inContext:(NSManagedObjectContext *)context error:(NSError **)error {
    if ( !error ) {
        NSError *err = nil;
        error = &err;
    }
    *error = nil;
    
    NSManagedObject *object = [context objectWithID:objectID];
    if ( ![object isFault] ) {
        return object;
    }
    
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [object entity];
    request.predicate = [NSPredicate predicateWithFormat:@"SELF = %@",object];
    NSArray* objects = [context executeFetchRequest:request error:error];
    if ( *error ) {
        [request release];
        *error = [NSError errorWithDomain:nil code:0 userInfo:[NSDictionary dictionaryWithObject:*error forKey:ROOT_ERROR]];
    }
    [request release];
    
    if ( [objects count] == 0 ) {
        return nil;
    }
    
    return [objects objectAtIndex:0];
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
