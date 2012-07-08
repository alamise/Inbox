//
//  ActivityManager.m
//  Inbox
//
//  Created by Simon Watiau on 7/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ActivityManager.h"

@implementation ActivityManager

- (void)activityStarted{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)activityEnded{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

@end