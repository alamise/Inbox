#import <Foundation/Foundation.h>
#define SYNC_DONE @"sync_done"
#define SYNC_FAILED @"sync_failed"
#define SYNC_RELOADED @"sync_reloaded"

@interface SynchroManager : NSObject{
    NSMutableArray *synchronizers;
    int runningSync;
    void(^onSyncStopped)();
}

@property(readonly) BOOL isSyncing;
- (void)startSync;
- (void)abortSync:(void(^)())onSyncStopped;
- (void)reloadAccountsWithError:(NSError **)error; 
@end
