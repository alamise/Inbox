//
//  Reader.m
//  Inbox
//
//  Created by Simon Watiau on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Reader.h"

@implementation Reader

-(NSManagedObjectContext*)newContext{
    return [(AppDelegate*)[UIApplication sharedApplication].delegate newManagedObjectContext];
}
@end
