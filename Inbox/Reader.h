//
//  Reader.h
//  Inbox
//
//  Created by Simon Watiau on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "AppDelegate.h"

@interface Reader : NSObject{
    NSManagedObjectContext* coreDataContext;
}
+(void)setInstance:(Reader*)ins;
+(Reader*)getInstance;
-(NSManagedObjectContext*)sharedContext;
@end
