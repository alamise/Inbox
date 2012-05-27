//
//  Synchronizer.h
//  Inbox
//
//  Created by Simon Watiau on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "errorCodes.h"
#import "FlurryAnalytics.h"

#define STATE_UPDATED @"state_updated"
@class NSManagedObjectContext;
@interface Synchronizer : NSObject{
    BOOL shouldStopAsap;
    NSLock* syncLock;
    NSManagedObjectContext *context;
}
- (void)startSync:(NSError **)error;
- (void)stopAsap;

// internal
- (void)sync:(NSError **)error;
- (void)onStateChanged;
- (void)saveContextWithError:(NSError **)error;
@property(readonly,assign) BOOL shouldStopAsap;
@property(nonatomic,retain) NSManagedObjectContext *context;
@end
