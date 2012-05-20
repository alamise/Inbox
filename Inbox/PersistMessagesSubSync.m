//
//  PersistMessagesSynchronizer.m
//  Inbox
//
//  Created by Simon Watiau on 5/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PersistMessagesSubSync.h"
#import <CoreData/CoreData.h>
#import "EmailModel.h"
#import "FolderModel.h"
#import "errorCodes.h"
#import "CTCoreFolder.h"
#import "CTCoreAccount.h"
#import "CTCoreFolder.h"
#import "EmailAccountModel.h"
@interface PersistMessagesSubSync ()
@end


@implementation PersistMessagesSubSync

-(void)syncWithError:(NSError**)error{
    [self updateRemoteMessagesWithError:error];
}


-(void)updateRemoteMessagesWithError:(NSError**)error{
    if (!error){
        NSError* err = nil;
        error = &err;
    }
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailModel entityName] inManagedObjectContext:self.context];
    request.entity = entity;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(shouldPropagate == YES) AND folder.account = %@",self.accountModel];
    [request setPredicate:predicate];
    NSError* fetchError = nil;
    NSArray* models = [self.context executeFetchRequest:request error:error];
    [request release];
    if (*error){
        *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:fetchError forKey:ROOT_ERROR]];
        return;
    }
    CTCoreFolder* folder = nil;
    BOOL skip;
    CTCoreAccount* account = nil;

    for (EmailModel* email in models){
        skip = false;
        if (folder==nil || ![folder.path isEqualToString:email.folder.path]){
            [folder disconnect];
            @try {
                account = [self coreAccountWithError:error];
                if (*error){
                    *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:*error forKey:ROOT_ERROR]];
                    return;
                }
                folder = [account folderWithPath:email.serverPath];
            }
            @catch (NSException *exception) {
                skip = true;
            }
        }
        
        CTCoreMessage* message;
        if (!skip){
            @try {
                // TODO: Should I use the UID or the messageID?
                message = [folder messageWithUID:email.uid];
            }
            @catch (NSException *exception) {
                skip = true;
            }
        }
        
        // If there were an issue finding the email on the server, the message is deleted.
        if (skip) {
            @try {
                [self.context deleteObject:email];
            }
            @catch (NSException *exception) {
                *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
                return;
            }
        } else {
            @try {
                [folder moveMessage:email.folder.path forMessage:message];
            }
            @catch (NSException* exception) {
                *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
                return;
            }
            email.serverPath = folder.path;
            email.shouldPropagate = NO;
        }
    }
}

@end
