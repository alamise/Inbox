#import <Foundation/Foundation.h>

@class CoreDataManager;
@class ThreadsManager;
@class SynchroManager;

@interface Deps : NSObject{
    CoreDataManager *coreDataManager;
    ThreadsManager *backgroundThread;
    SynchroManager *synchroManager;
}
+ (Deps *)sharedInstance;

@property(nonatomic,retain,readonly) SynchroManager *synchroManager;
@property(nonatomic,retain,readonly) CoreDataManager *coreDataManager;
@property(nonatomic,retain,readonly) ThreadsManager *threadsManager;

@end
