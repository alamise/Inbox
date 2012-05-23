//
//  Deps.m
//  Inbox
//
//  Created by Simon Watiau on 5/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Deps.h"
#import "BackgroundThread.h"
#import "CoreDataManager.h"
#import "SynchroManager.h"

static Deps* instance;

@interface Deps ()
@property(nonatomic, retain, readwrite) CoreDataManager* coreDataManager;
@property(nonatomic, retain, readwrite) BackgroundThread* backgroundThread;
@property(nonatomic, retain, readwrite) SynchroManager* synchroManager;
@end

@implementation Deps
@synthesize coreDataManager;
@synthesize backgroundThread;
@synthesize synchroManager;
+ (Deps*) sharedInstance{
    if (!instance){
        instance = [[Deps alloc] init];
    }
    return instance;
}


- (void) dealloc {
    self.coreDataManager = nil;
    self.backgroundThread = nil;
    self.synchroManager = nil;
    [super dealloc];
}

- (id) init {
    if (self = [super init]){
        self.backgroundThread = [[[BackgroundThread alloc] init] autorelease];
        [self.backgroundThread.thread start];
        
        self.coreDataManager = [[[CoreDataManager alloc] init] autorelease];

        self.synchroManager = [[[SynchroManager alloc] init] autorelease];
    }
    return self;
}

@end
