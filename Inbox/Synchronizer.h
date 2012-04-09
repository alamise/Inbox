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

@interface Synchronizer : NSObject
-(void)onError:(NSError*)error;
-(NSString*)decodeImapString:(NSString*)input;
-(BOOL)saveContext:(NSManagedObjectContext*)context errorCode:(int)errorCode;
@end
