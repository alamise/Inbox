//
//  ModelsManager.m
//  Inbox
//
//  Created by Simon Watiau on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ModelsManager.h"
#import "AppDelegate.h"
#import "models.h"
#import "NSObject+Queues.h"

@implementation ModelsManager



-(id)init{
    if (self = [super init]){
        synchronizers = [[NSMutableArray alloc] init];
        [self refreshEmailAccountsPool];
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

-(void)refreshEmailAccountsPool{
    for (Synchronizer* sync in synchronizers){
        [sync stopAsap];
    }
    [synchronizers removeAllObjects];
    
    NSManagedObjectContext* context = [[(AppDelegate*)[UIApplication sharedApplication].delegate newManagedObjectContext] retain];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailAccountModel entityName] inManagedObjectContext:context];
    request.entity = entity;
    [request setPropertiesToFetch:[entity properties]];
    NSError* fetchError;
    NSArray* emailsModels = [context executeFetchRequest:request error:&fetchError];
    if (fetchError){
        // TODO
        return;
    }

    for (EmailAccountModel* account in emailsModels){
        EmailSynchronizer* sync = [[EmailSynchronizer alloc] initWithAccount:account];
        [synchronizers addObject:sync];
    }
    
    [context release];
    [request release];
}


-(void)startSync{
    runningSync = [synchronizers count];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSyncFail) name:INTERNAL_SYNC_FAILED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSyncDone) name:INTERNAL_SYNC_DONE object:nil];
    for (Synchronizer* sync in synchronizers){
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [sync startSync];
        });
    }
}

-(void)onSyncDone{
    @synchronized(self){
        runningSync--;
        if (runningSync==0){
            [self executeOnMainQueue:^{
                [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_DONE object:nil];
            }];

        }
    }
}

-(void)onSyncFailed{
    [self executeOnMainQueue:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_FAILED object:nil];
    }];
}


@end
