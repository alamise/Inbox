#import <Foundation/Foundation.h>

@class CoreDataManager;
@class ThreadsManager;
@class SynchroManager;
@class DeskController;
@class ActivityManager;

@interface Deps : NSObject{
    CoreDataManager *coreDataManager;
    ThreadsManager *backgroundThread;
    SynchroManager *synchroManager;
    DeskController *deskController;
    ActivityManager *activityManager;
}
+ (Deps *)sharedInstance;

@property(nonatomic,retain,readonly) SynchroManager *synchroManager;
@property(nonatomic,retain,readonly) CoreDataManager *coreDataManager;
@property(nonatomic,retain,readonly) ThreadsManager *threadsManager;
@property(nonatomic,retain,readonly) DeskController *deskController;
@property(nonatomic,retain,readonly) ActivityManager *activityManager;

@end
