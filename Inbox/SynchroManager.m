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

@interface SynchroManager()
@property(nonatomic, retain) void(^onceAbortedBlock)();

@end

@implementation SynchroManager
@synthesize onceAbortedBlock;
-(id)init{
    if (self = [super init]){
        synchronizers = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)dealloc{
    self.onceAbortedBlock = nil;
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
    if ( !*error) {
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
    self.onceAbortedBlock = nil;
    NSError* error = nil;
    [self refreshEmailAccountsWithError:&error];
    if ( error ) {
        [self syncFailed];
        return;
    }
    
    runningSync = [synchronizers count];
    [[Deps sharedInstance].threadsManager performBlockOnBackgroundThread:^{            
        for ( Synchronizer* sync in synchronizers ) {
            NSError *error = nil;
            [sync startSync:&error];
            if ( error ){
                [self syncFailed];
            } else {
                [self syncDone];
            }
        }
    } waitUntilDone:NO];
}

- (void)abortSync:(void(^)())onceAborted {
    self.onceAbortedBlock = Block_copy(onceAborted);
    if ( [self isSyncing] ) {
        [self callStopAsapOnSynchronizers];
    } else {
        [[Deps sharedInstance].threadsManager performBlockOnMainThread:^{
            self.onceAbortedBlock();
            self.onceAbortedBlock = nil;
        } waitUntilDone:NO];
    }
}


- (void)callStopAsapOnSynchronizers {
    for ( Synchronizer* sync in synchronizers ) {
        [[Deps sharedInstance].threadsManager performBlockOnBackgroundThread:^{
            [sync stopAsap];
        } waitUntilDone:NO];
    }
}

- (void)syncDone {
    runningSync--;
    if ( runningSync < 0 ) runningSync = 0; /* this can be called before any sync start */
    if ( runningSync == 0 ) {
        [synchronizers removeAllObjects];
        if ( self.onceAbortedBlock == nil ) {
            [[Deps sharedInstance].threadsManager performBlockOnMainThread:^{
                [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_DONE object:nil];
            } waitUntilDone:NO];
        } else {
            self.onceAbortedBlock();
            self.onceAbortedBlock = nil;
        }
    }
}

- (void)syncFailed {
    runningSync--;
    if (runningSync < 0) runningSync = 0; /* this can be called before any sync start */
    if ( !self.onceAbortedBlock ) {
        self.onceAbortedBlock = ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_FAILED object:nil];
        };
    }
    if ( runningSync == 0 ) {
        [[Deps sharedInstance].threadsManager performBlockOnMainThread:^{
        self.onceAbortedBlock();
        } waitUntilDone:NO];
    }
}

- (BOOL)isSyncing {
    return runningSync != 0;
}

@end
