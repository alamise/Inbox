//
//  ModelsManager.m
//  Inbox
//
//  Created by Simon Watiau on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SynchroManager.h"
#import "EmailSynchronizer.h"
#import "Synchronizer.h"
#import "EmailAccountModel.h"
#import "ThreadsManager.h"
#import "Deps.h"
#import "CoreDataManager.h"
#import "errorCodes.h"
@implementation SynchroManager

-(id)init{
    if (self = [super init]){
        synchronizers = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)dealloc{
    for (Synchronizer* sync in synchronizers){
        [sync stopAsap];
    }
    [synchronizers release];
    [super dealloc];
}

- (void) reloadAccountsWithError:(NSError**)error {
    if (!error){
        NSError* err;
        error = &err;
    }
    *error = nil;
    
    [self refreshEmailAccountsWithError:error];
    if (!*error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_RELOADED object:nil];
    }
    
}

-(void) refreshEmailAccountsWithError:(NSError**)error {
    if ( !error ) {
        NSError* err;
        error = &err;
    }
    *error = nil;
    
    for ( Synchronizer* sync in synchronizers ) {
        [sync stopAsap];
    }
    [synchronizers removeAllObjects];
    
    NSManagedObjectContext* context = [[Deps sharedInstance].coreDataManager mainContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailAccountModel entityName] inManagedObjectContext:context];
    request.entity = entity;
    NSArray* emailsModels = [context executeFetchRequest:request error:error];
    if ( *error ) {
        [request release];
        *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:REFRESH_ACCOUNT_ERROR userInfo:[NSDictionary dictionaryWithObject:*error forKey:ROOT_ERROR]];
    }

    for ( EmailAccountModel* account in emailsModels ) {
        EmailSynchronizer* sync = [[EmailSynchronizer alloc] initWithAccountId:account.objectID];
        [synchronizers addObject:sync];
    }
    [request release];
    return;
}


-(void)startSync{
    NSError* error = nil;
    [self refreshEmailAccountsWithError:&error];
    if ( error ) {
        [self onSyncFailed];
        return;
    }
    
    runningSync = [synchronizers count];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSyncFailed) name:INTERNAL_SYNC_FAILED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSyncDone) name:INTERNAL_SYNC_DONE object:nil];
    for ( Synchronizer* sync in synchronizers ) {
        [[Deps sharedInstance].threadsManager performBlockOnBackgroundThread:^{            
            NSError *error = nil;
            [sync startSync:&error];
            if ( error ){
                [[Deps sharedInstance].threadsManager performBlockOnMainThread:^{
                    [self onSyncFailed];
                } waitUntilDone:NO];
            } else {
                [[Deps sharedInstance].threadsManager performBlockOnMainThread:^{
                    [self onSyncDone];
                } waitUntilDone:NO];            
            }
        } waitUntilDone:NO];
    }
}

- (void)abortSync {
    [self stopSynchronizers];
    [synchronizers removeAllObjects];
    runningSync = 0;
}


- (void)stopSynchronizers {
    for ( Synchronizer* sync in synchronizers ) {
        [[Deps sharedInstance].threadsManager performBlockOnBackgroundThread:^{
            [sync stopAsap];
        } waitUntilDone:NO];
    }
}

- (void)onSyncDone {
    runningSync--;
    if ( runningSync == 0 ) {
        [synchronizers removeAllObjects];
        [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_DONE object:nil];
    }
}


- (void)onSyncFailed {
    [self stopSynchronizers];
    [synchronizers removeAllObjects];
    runningSync = 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_FAILED object:nil];
}

- (BOOL)isSyncing {
    return runningSync != 0;
}

@end
