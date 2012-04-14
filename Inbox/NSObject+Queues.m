//
//  NSObject+Queues.m
//  Inbox
//
//  Created by Simon Watiau on 4/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSObject+Queues.h"

@implementation NSObject (Queues)
-(void)executeOnMainQueueSync:(dispatch_block_t) block{
    if (dispatch_get_current_queue() == dispatch_get_main_queue()){
        block();
    }else{
        dispatch_sync(dispatch_get_main_queue(), block);   
    }
}

-(void)executeOnMainQueueAsync:(dispatch_block_t) block{
    if (dispatch_get_current_queue() == dispatch_get_main_queue()){
        block();
    }else{
        dispatch_sync(dispatch_get_main_queue(), block);   
    }
}

@end
