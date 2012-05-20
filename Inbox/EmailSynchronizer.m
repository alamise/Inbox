//
//  EmailSynchronizer.m
//  Inbox
//
//  Created by Simon Watiau on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EmailSynchronizer.h"
#import "EmailAccountModel.h"
#import <CoreData/CoreData.h>
#import "CTCoreAccount.h"
#import "CTCoreMessage.h"
#import "AppDelegate.h"
#import "CTCoreFolder.h"
#import "MailCoreTypes.h"
#import "CTCoreAddress.h"
#import "FolderModel.h"
#import "EmailModel.h"
#import "DDLog.h"
#define ddLogLevel LOG_LEVEL_VERBOSE

@implementation EmailSynchronizer
@synthesize emailAccountModel;

-(id)initWithAccountId:(id)accountId{
    if (self = [super init]){
        emailAccountModelId = [accountId retain];
    }
    return self;
}

-(void)dealloc{
    [emailAccountModel release];
    [emailAccountModelId release];
    [super dealloc];
}


+(NSString*)decodeImapString:(NSString*)input {
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


#import "PersistMessagesSynchronizer.h"
#import "UpdateMessagesSynchronizer.h"
#import "FoldersSynchronizer.h"
-(BOOL)sync{
    
    
    emailAccountModel = (EmailAccountModel*)[[self.context objectWithID:emailAccountModelId] retain];
    
    NSError* error = nil;
    FoldersSynchronizer* foldersSync = [[FoldersSynchronizer alloc] initWithContext:self.context account:emailAccountModel];
    [foldersSync syncWithError:&error];
    if (error){
        return false;
    }
    [foldersSync release];
    
    
    PersistMessagesSynchronizer* persistSync = [[PersistMessagesSynchronizer alloc] initWithContext:self.context account:emailAccountModel];
    [persistSync syncWithError:&error];
    if (error){
        return false;
    }
    [persistSync release];
    
    
    UpdateMessagesSynchronizer* updateSync = [[UpdateMessagesSynchronizer alloc] initWithContext:self.context account:emailAccountModel];
    [updateSync syncWithError:&error onStateChanged:^{
        [self onStateChanged];
    }];
    if (error){
        return false;
    }
    [updateSync release];
    
    
    [emailAccountModel release];
    emailAccountModel = nil;
    return true;
}

@end
