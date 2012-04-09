//
//  Reader.h
//  Inbox
//
//  Created by Simon Watiau on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "models.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"

@interface Reader : NSObject
-(NSManagedObjectContext*)newContext;
@end
