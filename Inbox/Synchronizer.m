//
//  Synchronizer.m
//  Inbox
//
//  Created by Simon Watiau on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Synchronizer.h"
#import "NSObject+Queues.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "Deps.h"
#import "CoreDataManager.h"

@implementation Synchronizer
@synthesize shouldStopAsap;
@synthesize context;
-(id)init{
    if (self = [super init]){
        syncLock = [[NSLock alloc] init];
    }
    return self;
}

-(void)dealloc{
    self.context = nil;
    [syncLock release];
    [super dealloc];
}

-(void)onStateChanged{
    if (!self.shouldStopAsap){
        [self executeOnMainQueueAsync:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:STATE_UPDATED object:nil];
        }];
    }
}

-(void)onError:(NSError*)error{
    if (!self.shouldStopAsap){
        [self executeOnMainQueueSync:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:INTERNAL_SYNC_FAILED object:nil];
        }];
    }
}

-(BOOL)startSync{
    [syncLock lock];
    self.context = [[Deps sharedInstance].coreDataManager syncContext];
    shouldStopAsap = false;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncFailed) name:INTERNAL_SYNC_FAILED object:nil];
    BOOL returnValue = [self sync];
    self.context = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:INTERNAL_SYNC_FAILED object:nil];
    [syncLock unlock];
    if (!self.shouldStopAsap){
        [self executeOnMainQueueSync:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:INTERNAL_SYNC_DONE object:nil];
        }];
    }
    return returnValue;
}

-(BOOL)sync{
    return true;
}

-(void)syncFailed{
    [syncLock unlock];
    [self stopAsap];
}

-(void)saveContextWithError:(NSError**)error{
    if (!error){
        NSError* err = nil;
        error = &err;
    }
    [self.context save:error];
    return;
}

-(void)stopAsap{
    shouldStopAsap = true;
}


@end
