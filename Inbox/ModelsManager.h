//
//  ModelsManager.h
//  Inbox
//
//  Created by Simon Watiau on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "models.h"
#define SYNC_DONE @"sync_done"
#define SYNC_FAILED @"sync_failed"
@interface ModelsManager : NSObject{
    NSMutableArray* synchronizers;
    int runningSync;
}
@property(readonly)BOOL isSyncing;
-(void)startSync;
-(void)abortSync;
@end
