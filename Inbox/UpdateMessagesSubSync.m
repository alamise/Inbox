//
//  UpdateMessagesSynchronizer.m
//  Inbox
//
//  Created by Simon Watiau on 5/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UpdateMessagesSubSync.h"
#import <CoreData/CoreData.h>
#import "EmailModel.h"
#import "FolderModel.h"
#import "errorCodes.h"
#import "CTCoreFolder.h"
#import "CTCoreAccount.h"
#import "CTCoreFolder.h"
#import "EmailAccountModel.h"
#import "EmailSynchronizer.h"
#import "CTCoreMessage.h"
#import "CTCoreAddress.h"

@interface UpdateMessagesSubSync ()
@end



@implementation UpdateMessagesSubSync


-(void)syncWithError:(NSError**)error onStateChanged:(void(^)()) osc{
    onStateChanged = [osc retain];
    [self updateLocalMessagesWithError:error];
    [osc release];
    osc = nil;
}

-(void)updateLocalMessagesWithError:(NSError**)error {

    /* get the folders model */
    NSFetchRequest *foldersRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *folderDescription = [NSEntityDescription entityForName:[FolderModel entityName] inManagedObjectContext:self.context];
    foldersRequest.entity =folderDescription;

    NSMutableArray* folders = [NSMutableArray arrayWithArray:[self.context executeFetchRequest:foldersRequest error:error]];
    [foldersRequest release];
    
    if (*error){
        *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:*error forKey:ROOT_ERROR]];
        return;
    }
    

    int currentFolderIndex = 0;
    int page = 0;
    int pageSize = 100;
    CTCoreFolder *currentCoreFolder = nil;
    int updateRemoteCounter = 0;
    NSMutableDictionary* totalMessageCount = [NSMutableDictionary dictionary];
    
    while ([folders count]!=0){
        NSLog(@"loop");
        if (updateRemoteCounter++%30 == 0){
            // TODO update remote messages sometimes
        }
        NSSet* messagesBuffer = nil;
        @try {
            CTCoreAccount* account = [self coreAccountWithError:error];
            if (*error){
                return;
            }   
            
            // Check this : http://github.com/mronge/MailCore/issues/2
            [currentCoreFolder disconnect];
            currentCoreFolder = [account folderWithPath:((FolderModel*)[folders objectAtIndex:currentFolderIndex]).path]; 
            [currentCoreFolder connect];
            if (![totalMessageCount objectForKey:((FolderModel*)[folders objectAtIndex:currentFolderIndex]).objectID]){
                [totalMessageCount setObject:[NSNumber numberWithInt:[currentCoreFolder totalMessageCount]] forKey:((FolderModel*)[folders objectAtIndex:currentFolderIndex]).objectID];
            }
        }
        @catch (NSException *exception) {
            *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
            return;
        }

        @try {
            int start = [((NSNumber*)[totalMessageCount objectForKey:((FolderModel*)[folders objectAtIndex:currentFolderIndex]).objectID]) intValue] - (page+1) * pageSize; 
            if (start<0) start = 0;
            int end = [((NSNumber*)[totalMessageCount objectForKey:((FolderModel*)[folders objectAtIndex:currentFolderIndex]).objectID]) intValue] - (page) * pageSize;
            if (end<0) end = 0;
            messagesBuffer = [currentCoreFolder messageObjectsFromIndex:start toIndex:end];
        }
        @catch (NSException *exception) {
            *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
            return;
        }
        
        for (CTCoreMessage* message in messagesBuffer){
            FolderModel* currentFolderModel = nil;
                    NSLog(@"loop2");
            // get the email's folder model            
            NSFetchRequest *folderRequest = [[NSFetchRequest alloc] init];
            NSEntityDescription *folderEntity = [NSEntityDescription entityForName:[FolderModel entityName] inManagedObjectContext:self.context];
            folderRequest.entity = folderEntity;
            [folderRequest setFetchLimit:1];
            NSPredicate *folderPredicate = [NSPredicate predicateWithFormat:@"path = %@",[EmailSynchronizer decodeImapString:currentCoreFolder.path],self.accountModel];
            [folderRequest setPredicate:folderPredicate];

            NSArray* f = [self.context executeFetchRequest:folderRequest error:error];
            
            [folderRequest release];
            if (*error){
                *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:*error forKey:ROOT_ERROR]];
                return;
            }else if ([f count] == 0){
                *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:nil];
                return;
            }
            currentFolderModel = [f lastObject];
            
            
            NSFetchRequest *emailRequest = [[NSFetchRequest alloc] init];
            NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailModel entityName] inManagedObjectContext:self.context];
            emailRequest.entity = entity;    
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sentDate" ascending:YES];
            [emailRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
            [sortDescriptor release];
            
            EmailModel* emailModel=nil;
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uid = %@ AND folder = %@", message.uid,currentFolderModel];
            [emailRequest setPredicate:predicate];

            NSArray* matchingEmails = [[self.context executeFetchRequest:emailRequest error:error] retain];
            [emailRequest release];
            if (*error){

                *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:*error forKey:ROOT_ERROR]];
                [matchingEmails release];
                return;   
            }
            if ([matchingEmails count]>0){
                emailModel = [matchingEmails objectAtIndex:0];
            }else{
                @try {
                    emailModel = [NSEntityDescription insertNewObjectForEntityForName:[EmailModel entityName] inManagedObjectContext:self.context];
                }
                @catch (NSException *exception) {
                  *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
                    [matchingEmails release];   
                    return;   
                }
            }
            [matchingEmails release];
            NSEnumerator* enumerator = [message.from objectEnumerator];
            CTCoreAddress* from;
            
            // The "sender" field is not valid
            if ([message.from count]>0){
                from = [enumerator nextObject];
            }else{
                from = message.sender;
            }

            emailModel.senderName = from.name;
            emailModel.senderEmail = from.email;
            emailModel.subject=message.subject;
            emailModel.sentDate = message.sentDateGMT;
            emailModel.uid = message.uid;
            emailModel.serverPath = currentCoreFolder.path;
            emailModel.read = !message.isUnread;
            emailModel.folder = currentFolderModel;
        }
        
        /* If ther eis no more messages in a folder. We remove it from the list */
        if ([messagesBuffer count]==0){
            [folders removeObject:[folders objectAtIndex:currentFolderIndex]];
        }

        [self.context save:error];
        if (*error){
            return;
        }
        
        onStateChanged();
        /* process the following 20 mails of the next folder */
        currentFolderIndex = currentFolderIndex+1;
        currentFolderIndex = currentFolderIndex % [folders count];
        /* Increase the current page when we loaded this one for all the folders */
        if (currentFolderIndex==0){
            page++;
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
