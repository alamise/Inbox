#import <Foundation/Foundation.h>

@interface ThreadsManager : NSObject{
    BOOL shouldStop;
    NSThread* thread;
}
@property(readonly,nonatomic,retain) NSThread* thread;
-(void)stop;

-(void)performBlockOnBackgroundThread:(void(^)()) block waitUntilDone:(BOOL)waitUntilDone;
-(void)performBlockOnMainThread:(void(^)()) block waitUntilDone:(BOOL)waitUntilDone;
@end
