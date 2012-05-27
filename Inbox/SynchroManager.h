//
//  ModelsManager.h
//  Inbox
//
//  Created by Simon Watiau on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#define SYNC_DONE @"sync_done"
#define SYNC_FAILED @"sync_failed"
#define SYNC_RELOADED @"sync_reloaded"

@interface SynchroManager : NSObject{
    NSMutableArray *synchronizers;
    int runningSync;
    void(^onceAbortedBlock)();
}

@property(readonly)BOOL isSyncing;
- (void)startSync;
- (void)abortSync:(void(^)())onceAborted;

- (void)reloadAccountsWithError:(NSError **)error; 
@end
