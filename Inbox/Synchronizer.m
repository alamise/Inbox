//
//  Synchronizer.m
//  Inbox
//
//  Created by Simon Watiau on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Synchronizer.h"
#import "ThreadsManager.h"
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

- (void)onStateChanged {
    if (!self.shouldStopAsap){
        [[Deps sharedInstance].threadsManager performBlockOnMainThread:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:STATE_UPDATED object:nil];        
        } waitUntilDone:NO];
    }
}

- (void)startSync:(NSError **)error {
    if ( !error ) {
        NSError *err = nil;
        error = &err;
    }
    *error = nil;
    [syncLock lock];
    self.context = [[Deps sharedInstance].coreDataManager syncContext];
    shouldStopAsap = false;
    [self sync:error];
    self.context = nil;
    if ( self.shouldStopAsap ) {
        *error = nil;
    }
    [syncLock unlock];
}

/* Overriden */
- (void)sync:(NSError **)error{

}

- (void)saveContextWithError:(NSError **)error{
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
