//
//  PrivateValues.m
//  Inbox
//
//  Created by Simon Watiau on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PrivateValues.h"
static PrivateValues* instance;
@implementation PrivateValues

+(PrivateValues*)sharedInstance{
    if (!instance){
        instance = [[PrivateValues alloc] init];
    }
    return instance;
}

-(id)init{
    if (self = [super init]){
        values = [[NSDictionary dictionaryWithContentsOfFile:@"private.plist"] retain];
    }
    return self;
}


-(NSString*)flurryApiKey{
    return [values objectForKey:@"flurryApiKey"];
}

-(NSString*)quincyServer{
    return [values objectForKey:@"quincyServer"];
}

@end
