//
//  Deps.h
//  Inbox
//
//  Created by Simon Watiau on 5/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CoreDataManager;
@class BackgroundThread;
@class SynchroManager;
@interface Deps : NSObject{
    CoreDataManager* coreDataManager;
    BackgroundThread* backgroundThread;
    SynchroManager* synchroManager;
}
+ (Deps*) sharedInstance;

@property(nonatomic,retain,readonly) SynchroManager* synchroManager;
@property(nonatomic,retain,readonly) CoreDataManager* coreDataManager;
@property(nonatomic,retain,readonly) BackgroundThread* backgroundThread;

@end
