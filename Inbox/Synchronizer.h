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

@interface Synchronizer : NSObject{
    BOOL shouldStopAsap;
    NSLock* syncLock;
}
@property(readonly,assign) BOOL shouldStopAsap;
-(void)onError:(NSError*)error;
-(NSString*)decodeImapString:(NSString*)input;
-(BOOL)saveContext:(NSManagedObjectContext*)context errorCode:(int)errorCode;

-(BOOL)startSync;
// internal
-(BOOL)sync;
-(void)stopAsap;
@end
