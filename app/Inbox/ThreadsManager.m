#import "ThreadsManager.h"

@implementation ThreadsManager
@synthesize thread;

-(id)init {
    if (self = [super init]) {
        thread = [[NSThread alloc] initWithTarget:self selector:@selector(loop) object:nil];
    }
    return self;
}

-(void) dealloc{
    [self stop];
    [thread release];
    [super dealloc];
}

-(void) stop {
    shouldStop = YES;
}

/*
 * While the synchro is running, nothing can be run on the background thread (we stay in the same cycle ot the runloop)
 */
-(void)performBlockOnBackgroundThread:(void(^)()) block waitUntilDone:(BOOL)waitUntilDone {
    [self performSelector:@selector(doBlock:) onThread:thread withObject:[[block copy] autorelease] waitUntilDone:waitUntilDone];
}

-(void)performBlockOnMainThread:(void(^)()) block waitUntilDone:(BOOL)waitUntilDone {
    [self performSelectorOnMainThread:@selector(doBlock:) withObject:[[block copy] autorelease] waitUntilDone:waitUntilDone];
}

-(void)doBlock:(void(^)())block{
    block();
}

-(void)keepAliveTimerAction:(NSTimer*)timer{
}

-(void)loop {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    NSTimer* keepAliveTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(keepAliveTimerAction:) userInfo:nil repeats:YES];
    BOOL stop = NO;
    do {
        SInt32 result = CFRunLoopRunInMode(kCFRunLoopDefaultMode, 10, YES);
        if (result == kCFRunLoopRunStopped || result == kCFRunLoopRunFinished){
            stop = YES;
        }
        
        
        if (shouldStop){
            [keepAliveTimer invalidate];
            stop = YES;
        }
    } while(!stop);
    
    [pool release];
}


@end
