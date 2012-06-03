#import <Foundation/Foundation.h>
#define SYNC_DONE @"sync_done"
#define SYNC_FAILED @"sync_failed"
#define SYNC_RELOADED @"sync_reloaded"
#define SYNC_STOPPING @"sync_stopping" /* a SYNC_DONE event is sent once the snchro is done */

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
