//
//  Synchronizer.h
//  Inbox
//
//  Created by Simon Watiau on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "errorCodes.h"
#import "models.h"
#import "FlurryAnalytics.h"

#define INTERNAL_SYNC_FAILED @"int_sync_failed"
#define INTERNAL_SYNC_DONE @"int_sync_done"
#define STATE_UPDATED @"state_updated"
@class NSManagedObjectContext;
@interface Synchronizer : NSObject{
    BOOL shouldStopAsap;
    NSLock* syncLock;
    NSManagedObjectContext* context;
}
-(BOOL)startSync;
-(void)stopAsap;

// internal
-(BOOL)sync;
-(void)onStateChanged;
-(void)onError:(NSError*)error;
-(NSString*)decodeImapString:(NSString*)input;
-(void)saveContextWithError:(NSError**)error;
@property(readonly,assign) BOOL shouldStopAsap;
@property(nonatomic,retain) NSManagedObjectContext* context;
@end
