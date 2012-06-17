#import <Foundation/Foundation.h>
#define SYNC_STARTED @"sync_started"
#define SYNC_DONE @"sync_done"
#define SYNC_FAILED @"sync_failed"

@interface SynchroManager : NSObject{
    NSMutableArray *synchronizers;
    int runningSync;
    void(^onSyncStopped)();
}

@property(readonly) BOOL isSyncing;
- (void)startSync;
- (void)abortSync:(void(^)())onSyncStopped;
@end
