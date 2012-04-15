//
//  ModelsManager.m
//  Inbox
//
//  Created by Simon Watiau on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ModelsManager.h"
#import "AppDelegate.h"
#import "NSObject+Queues.h"
#import "EmailSynchronizer.h"
#import "Synchronizer.h"
#import "EmailAccountModel.h"
@implementation ModelsManager

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

-(BOOL)refreshEmailAccounts{
    for (Synchronizer* sync in synchronizers){
        [sync stopAsap];
    }
    [synchronizers removeAllObjects];
    
    NSManagedObjectContext* context = [[(AppDelegate*)[UIApplication sharedApplication].delegate newManagedObjectContext] retain];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailAccountModel entityName] inManagedObjectContext:context];
    request.entity = entity;
    NSError* fetchError = nil;
    NSArray* emailsModels = [context executeFetchRequest:request error:&fetchError];
    if (fetchError){
        
        [context release];
        [request release];
        return false;
    }

    for (EmailAccountModel* account in emailsModels){
        EmailSynchronizer* sync = [[EmailSynchronizer alloc] initWithAccountId:account.objectID];
        [synchronizers addObject:sync];
    }
    
    [context release];
    [request release];
    return true;
}


-(void)startSync{
    if(![self refreshEmailAccounts]){
        [self onSyncFailed];
        return;
    }
    runningSync = [synchronizers count];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSyncFailed) name:INTERNAL_SYNC_FAILED object:nil];
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
            [self executeOnMainQueueSync:^{
                [synchronizers removeAllObjects];
                [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_DONE object:nil];
            }];

        }
    }
}

-(void)onSyncFailed{
    for (Synchronizer* sync in synchronizers){
        [sync stopAsap];
    }
    [synchronizers removeAllObjects];
    [self executeOnMainQueueSync:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_FAILED object:nil];
    }];
}


@end
