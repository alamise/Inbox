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
#import "DDLog.h"
#import "Logger.h"
@interface PersistMessagesSubSync ()
@end


@implementation PersistMessagesSubSync

-(void)syncWithError:(NSError**)error{
    [self updateRemoteMessagesWithError:error];
}


- (void)updateRemoteMessagesWithError:(NSError **)error {
    if ( self.shouldStopAsap ) return ;/* STOP ASAP */
    DDLogVerbose(@"Update remote messages started");

    if (!error){
        NSError* err = nil;
        error = &err;
    }
    *error = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailModel entityName] inManagedObjectContext:self.context];
    request.entity = entity;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(shouldPropagate == YES) AND folder.account = %@",self.accountModel];
    [request setPredicate:predicate];
    NSError* fetchError = nil;
    NSArray* models = [self.context executeFetchRequest:request error:error];
    [request release];
    if ( self.shouldStopAsap ) return ;/* STOP ASAP */
    if (*error){
        *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:fetchError forKey:ROOT_ERROR]];
        DDLogError(@"Update remote messages ended with an error");
        return;
    }
    CTCoreFolder* folder = nil;
    BOOL skip;
    CTCoreAccount* account = nil;

    for (EmailModel* email in models){
        if ( self.shouldStopAsap ) return ;/* STOP ASAP */
        skip = false;
        if (folder==nil || ![folder.path isEqualToString:email.folder.path]){
            [folder disconnect];
            @try {
                account = [self coreAccountWithError:error];
                if (*error){
                    *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:*error forKey:ROOT_ERROR]];
                    DDLogError(@"Update remote messages ended with an error");
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
        if ( self.shouldStopAsap ) return ;/* STOP ASAP */
        // If there were an issue finding the email on the server, the message is deleted locally.
        if (skip) {
            @try {
                [self.context deleteObject:email];
            }
            @catch (NSException *exception) {
                *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
                DDLogError(@"Update remote messages ended with an error");
                return;
            }
        } else {
            @try {
                [folder moveMessage:email.folder.path forMessage:message];
            }
            @catch (NSException* exception) {
                *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
                DDLogError(@"Update remote messages ended with an error");
                return;
            }
            email.serverPath = folder.path;
            email.shouldPropagate = [NSNumber numberWithBool:NO];
        }
    }
    [self.context save:error];
    if ( *error ) {
        *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_FOLDERS_ERROR userInfo:[NSDictionary dictionaryWithObject:*error forKey:ROOT_ERROR]];
        DDLogError(@"Update remote messages ended with an error");
        return;
    }

    DDLogVerbose(@"Update remote messages successful");
}

@end
