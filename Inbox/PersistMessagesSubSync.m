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
        [request release];
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
                    return;
                }
                folder = [account folderWithPath:email.serverPath];// bug la au reboot 
                //+ cehck la difference entre messageId et UID sur un CTCoreMessge.
            }
            @catch (NSException *exception) {
                skip = true;
            }
        }
        
        CTCoreMessage* message;
        if (!skip){
            @try {
                message = [folder messageWithUID:email.uid];
            }
            @catch (NSException *exception) {
                skip = true;
            }
        }
        
        // If there were an issue finding the email on the server, the message is deleted.
        if (skip){
            @try {
                [self.context deleteObject:email];
            }
            @catch (NSException *exception) {
                *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
                return;
            }
        }else{
            @try {
                [folder moveMessage:email.folder.path forMessage:message];
            }
            @catch (NSException* exception) {
                *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
                [request release];
                return;
            }
            email.serverPath = folder.path;
            email.shouldPropagate = NO;
        }
    }
    return;
}

-(CTCoreAccount*)coreAccountWithError:(NSError**)error {
    if (coreAccount == nil){
        coreAccount = [[CTCoreAccount alloc] init];
    }
    if (![coreAccount isConnected]){
        @try {
            
            [coreAccount connectToServer:self.accountModel.serverAddr port:[self.accountModel.port intValue] connectionType:[self.accountModel.conType intValue] authType:[self.accountModel.authType intValue] login:self.accountModel.login password:self.accountModel.password];            
        }
        @catch (NSException *exception) {
            *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
            return nil;
        }
    }
    return coreAccount;
}

@end
