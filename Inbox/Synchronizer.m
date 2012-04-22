//
//  Synchronizer.m
//  Inbox
//
//  Created by Simon Watiau on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Synchronizer.h"
#import "NSObject+Queues.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"

@implementation Synchronizer
@synthesize shouldStopAsap;
@synthesize context;
-(id)init{
    if (self = [super init]){
        syncLock = [[NSLock alloc] init];
    }
    return self;
}

-(void)dealloc{
    self.context = nil;
    [syncLock release];
    [super dealloc];
}

-(void)onStateChanged{
    if (!self.shouldStopAsap){
        [self executeOnMainQueueAsync:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:STATE_UPDATED object:nil];
        }];
    }
}

-(void)onError:(NSError*)error{
    if (!self.shouldStopAsap){
        [self executeOnMainQueueSync:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:INTERNAL_SYNC_FAILED object:nil];
        }];
    }
}

-(NSString*)decodeImapString:(NSString*)input{
    NSMutableDictionary* translationTable = [[NSMutableDictionary alloc] init];
    [translationTable setObject:@"&" forKey:@"&-"];
    [translationTable setObject:@"é" forKey:@"&AOk-"];
    [translationTable setObject:@"â" forKey:@"&AOI-"];
    [translationTable setObject:@"à" forKey:@"&AOA-"];
    [translationTable setObject:@"è" forKey:@"&AOg"];
    [translationTable setObject:@"ç" forKey:@"&AOc"];
    [translationTable setObject:@"ù" forKey:@"&APk"];
    [translationTable setObject:@"ê" forKey:@"&AOo"];
    [translationTable setObject:@"î" forKey:@"&AO4"];
    [translationTable setObject:@"ó" forKey:@"&APM"];
    [translationTable setObject:@"ñ" forKey:@"&APE"];
    [translationTable setObject:@"á" forKey:@"&AOE"];
    [translationTable setObject:@"ô" forKey:@"&APQ"];                   
    [translationTable setObject:@"É" forKey:@"&AMk"];
    [translationTable setObject:@"ë" forKey:@"&AOs"];
    
    for (NSString* key in [translationTable allKeys]){
        input = [input stringByReplacingOccurrencesOfString:key withString:[translationTable objectForKey:key]];
    }
    [translationTable release];
    return input;
}

-(BOOL)startSync{
    [syncLock lock];
    self.context = [(AppDelegate*)[UIApplication sharedApplication].delegate newManagedObjectContext];
    shouldStopAsap = false;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncFailed) name:INTERNAL_SYNC_FAILED object:nil];
    BOOL returnValue = [self sync];
    self.context = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:INTERNAL_SYNC_FAILED object:nil];
    [syncLock unlock];
    if (!self.shouldStopAsap){
        [self executeOnMainQueueSync:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:INTERNAL_SYNC_DONE object:nil];
        }];
    }
    return returnValue;
}

-(BOOL)sync{
    return true;
}

-(void)syncFailed{
    [syncLock unlock];
    [self stopAsap];
}

-(BOOL)saveContextWithError:(int)errorCode{
    NSError* error = nil;
    [self.context save:&error];
    if (error && !self.shouldStopAsap){
        [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:errorCode userInfo:[NSDictionary dictionaryWithObject:error forKey:ROOT_ERROR]]];
        return false;
    }else{
        return true;
    }
}

-(void)stopAsap{
    shouldStopAsap = true;
}

@end
