//
//  Synchronizer.m
//  Inbox
//
//  Created by Simon Watiau on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Synchronizer.h"
#import "NSObject+Queues.h"
@implementation Synchronizer


-(id)init{
    if (self = [super init]){
        syncLock = [[NSLock alloc] init];
    }
    return self;
}

-(void)dealloc{
    [syncLock release];
    [super dealloc];
}

-(void)onError:(NSError*)error{
    [self executeOnMainQueue:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:INTERNAL_SYNC_FAILED object:nil];
    }];
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
    shouldStopAsap = false;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(modelFailed) name:INTERNAL_SYNC_FAILED object:nil];
    BOOL returnValue = [self sync];
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:INTERNAL_SYNC_FAILED];
    [syncLock unlock];
    [self executeOnMainQueue:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:INTERNAL_SYNC_DONE object:nil];
    }];
    return returnValue;
}

-(BOOL)sync{
    return true;
}

-(void)syncFailed{
    [syncLock unlock];
    [self stopAsap];
}

-(BOOL)saveContext:(NSManagedObjectContext*)context errorCode:(int)errorCode{
    NSError* error = nil;
    [context save:&error];
    if (error){
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
