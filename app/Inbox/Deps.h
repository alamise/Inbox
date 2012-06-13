#import <Foundation/Foundation.h>

@class CoreDataManager;
@class ThreadsManager;
@class SynchroManager;
@class DeskController;
@interface Deps : NSObject{
    CoreDataManager *coreDataManager;
    ThreadsManager *backgroundThread;
    SynchroManager *synchroManager;
    DeskController *deskController;
}
+ (Deps *)sharedInstance;

@property(nonatomic,retain,readonly) SynchroManager *synchroManager;
@property(nonatomic,retain,readonly) CoreDataManager *coreDataManager;
@property(nonatomic,retain,readonly) ThreadsManager *threadsManager;
@property(nonatomic,retain,readonly) DeskController *deskController;

@end
