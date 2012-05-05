//
//  Reader.m
//  Inbox
//
//  Created by Simon Watiau on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Reader.h"
static Reader* instance;
@implementation Reader

+(void)setInstance:(Reader*)ins{
    [instance autorelease];
    instance = [ins retain];
}

+(Reader*)getInstance{
    return instance;
}

+(Reader*)sharedInstance{
    return nil;
}

-(NSManagedObjectContext*)sharedContext{
    return [(AppDelegate*)[UIApplication sharedApplication].delegate mainContext];
}

@end
