//
//  BackgroundThread.h
//  Inbox
//
//  Created by Simon Watiau on 5/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

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
