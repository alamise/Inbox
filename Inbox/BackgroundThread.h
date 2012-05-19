//
//  BackgroundThread.h
//  Inbox
//
//  Created by Simon Watiau on 5/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BackgroundThread : NSObject{
    BOOL shouldStop;
    NSThread* thread;
}
@property(readonly,nonatomic,retain) NSThread* thread;
-(void)stop;
-(void) performBlock:(void(^)())block waitUntilDone:(BOOL)wait;
@end
