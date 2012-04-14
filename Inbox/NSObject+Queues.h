//
//  NSObject+Queues.h
//  Inbox
//
//  Created by Simon Watiau on 4/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Queues)
-(void)executeOnMainQueueSync:(dispatch_block_t) block;
-(void)executeOnMainQueueAsync:(dispatch_block_t) block;
@end
