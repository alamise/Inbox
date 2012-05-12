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

-(id)initWithAccountId:(id)accountId{
    if (self = [super init]){
        emailAccountModelId = accountId;
    }
    return self;
}

-(void)dealloc{
    [emailAccountModel release];
    [emailAccountModelId release];
    [super dealloc];
}

-(BOOL)updateLocalFolders{
    if (self.shouldStopAsap){
        return true;
    }
    DDLogVerbose(@"[%@] update local folders started",emailAccountModel.login);
    NSSet* folders = nil;
    CTCoreAccount* account = [self account];
    if (account==nil){
        return false;
    }
    if (self.shouldStopAsap){
        return true;
    }
    @try {
        folders = [account allFolders];
    }
    @catch (NSException *exception) {
        DDLogError(@"[%@] error when retrieving the folders",emailAccountModel.login);
        [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_FOLDERS_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
        return false;
    }
    if (self.shouldStopAsap){
        return true;
    }
    
    NSArray* disabledFolders = [[NSArray alloc] initWithObjects:
                                NSLocalizedString(@"folderModel.path.drafts", @"Localized Drafts folder's path en: \"Drafts\""),
                                NSLocalizedString(@"folderModel.path.sent", @"Localized Sent folder's path en: \"[Gmail]/Sent Mail\""),
                                NSLocalizedString(@"folderModel.path.notes", @"Localized Notes folder's path en: \"Notes\""),
                                @"[Gmail]",
                                nil];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[FolderModel entityName] inManagedObjectContext:self.context];
    request.entity = entity;
    // Delete local folders that does not exist remotely
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(NOT(path IN %@) OR (path IN %@)) AND account = %@", folders,disabledFolders,emailAccountModel];          
    [request setPredicate:predicate];
    NSError* fetchError = nil;
    NSArray* foldersToDelete = [self.context executeFetchRequest:request error:&fetchError];
        DDLogVerbose(@"[%@] Deleting folders that does not exist on the server",emailAccountModel.login);
    if (fetchError){
        DDLogError(@"[%@] Error when getting the folders to delete list",emailAccountModel.login);
        [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_FOLDERS_ERROR userInfo:[NSDictionary dictionaryWithObject:fetchError forKey:ROOT_ERROR]]];
        [disabledFolders release];
        [request release];
        return false;
    }
    if (self.shouldStopAsap){
        return true;
    }
    for (FolderModel* folder in foldersToDelete){
        if (self.shouldStopAsap){
            return true;
        }
        @try {
            [self.context deleteObject:folder];
        }
        @catch (NSException *exception) {
            DDLogError(@"[%@] error when deleting folders",emailAccountModel.login);
            [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_FOLDERS_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]]];
            [disabledFolders release];
            [request release];
            return false;
        }
    }
    DDLogVerbose(@"[%@] folders deleted",emailAccountModel.login);
    for (NSString* path in folders){
        if (self.shouldStopAsap){
            return true;
        }
        if (![disabledFolders containsObject:path]){
            DDLogVerbose(@"[%@] processing folder %@",emailAccountModel.login, path);
            NSLog(@"%@",emailAccountModel.objectID);
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"path = %@ AND account = %@", path, emailAccountModel];
            [request setPredicate:predicate];
            
            NSError* fetchError = nil;
            int folders = [self.context countForFetchRequest:request error:&fetchError];
            if (fetchError){
                DDLogError(@"[%@] Error when testing if the folder %@ exists",emailAccountModel.login, path);
                [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_FOLDERS_ERROR userInfo:[NSDictionary dictionaryWithObject:fetchError forKey:ROOT_ERROR]]];
                [disabledFolders release];
                [request release];
                return false;
            }
            if (folders==0){
                DDLogVerbose(@"[%@] folder %@ does not exist. creating",emailAccountModel.login,path);
                FolderModel* folderModel;
                @try {
                    folderModel = [NSEntityDescription insertNewObjectForEntityForName:[FolderModel entityName] inManagedObjectContext:context];
                }
                @catch (NSException *exception) {
                    DDLogVerbose(@"[%@] error when creating the new folder %@",emailAccountModel.login, path);
                    [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_FOLDERS_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]]];
                    [disabledFolders release];
                    [request release];
                    return false;
                }
                folderModel.path = path;
                folderModel.account = emailAccountModel;
            }
        
        }
    }
    [disabledFolders release];
    [request release];
    DDLogVerbose(@"[%@] folders updated, saving context",emailAccountModel.login);
    if (self.shouldStopAsap){
        return true;
    }
    if (![self saveContextWithError:EMAIL_FOLDERS_ERROR]){
        DDLogError(@"[%@] Error when saving the context",emailAccountModel.login);
        return false;
    }else{
        return true;
    }
}


/*
 * Commit local changes to the server.
 * If a message is not found on the server, it's deleted locally.
 */
-(BOOL)updateRemoteMessages{
    if (self.shouldStopAsap){
        return true;
    }
    DDLogVerbose(@"[%@] committing local changes",emailAccountModel.login);
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailModel entityName] inManagedObjectContext:self.context];
    request.entity = entity;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(shouldPropagate == YES) AND folder.account = %@",emailAccountModel];
    [request setPredicate:predicate];
    NSError* fetchError = nil;
    NSArray* models = [self.context executeFetchRequest:request error:&fetchError];
    [request release];
    if (fetchError){
        DDLogError(@"[%@] Error when getting the modified messages ",emailAccountModel.login);
        [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:fetchError forKey:ROOT_ERROR]]];
        [request release];
        return false;
    }
    CTCoreFolder* folder = nil;
    BOOL skip;
    CTCoreAccount* account = nil;
    if (self.shouldStopAsap){
        return true;
    }
    for (EmailModel* email in models){
        if (self.shouldStopAsap){
            return true;
        }
        skip = false;
        if (folder==nil || ![folder.path isEqualToString:email.folder.path]){
            [folder disconnect];
            @try {
                account = [self account];
                if (account == nil){
                    return false;
                }
                folder = [account folderWithPath:email.serverPath];// bug la au reboot 
                //+ cehck la difference entre messageId et UID sur un CTCoreMessge.
            }
            @catch (NSException *exception) {
                skip = true;
                DDLogVerbose(@"[%@] error when getting the matching folder on the server, skipping this email",emailAccountModel.login);
            }
        }
        
        CTCoreMessage* message;
        if (!skip){
            @try {
                message = [folder messageWithUID:email.uid];
            }
            @catch (NSException *exception) {
                skip = true;
                DDLogVerbose(@"[%@] error when getting the matching message in the folder, skipping this email",emailAccountModel.login);
            }
        }
        
        // If there were an issue finding the email on the server, the message is deleted.
        if (skip){
            DDLogVerbose(@"[%@] The current message is skipped : deleting it locally",emailAccountModel.login);
            @try {
                [self.context deleteObject:email];
            }
            @catch (NSException *exception) {
                DDLogError(@"[%@] Error when deleting the current email",emailAccountModel.login);
                [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]]];
                [request release];
                return false; 
            }
        }else{
            @try {
                [folder moveMessage:email.folder.path forMessage:message];
            }
            @catch (NSException* exception) {
                [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]]];
                [request release];
                return false;
            }
            email.serverPath = folder.path;
            email.shouldPropagate = NO;
        }
    }
    return true;
}

-(BOOL)updateLocalMessages{
    if (self.shouldStopAsap){
        return true;
    }
    DDLogVerbose(@"[%@] Updating local messages",emailAccountModel.login);

    
    /* get the folders model */
    NSFetchRequest *foldersRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *folderDescription = [NSEntityDescription entityForName:[FolderModel entityName] inManagedObjectContext:self.context];
    foldersRequest.entity =folderDescription;
    
    NSError* fetchError = nil;
    NSLog(@"%@",self.context);
    NSMutableArray* folders = [NSMutableArray arrayWithArray:[self.context executeFetchRequest:foldersRequest error:&fetchError]];
    DDLogVerbose(@"[%@] Getting the folders",emailAccountModel.login);
    if (fetchError){
        DDLogError(@"[%@] Error when getting folders",emailAccountModel.login);
        [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:fetchError forKey:ROOT_ERROR]]];
        [foldersRequest release];
        return false;
    }
    [foldersRequest release];
    
    /* Prepare the request used to test if a message is already is the base */
    
    
    if (self.shouldStopAsap){
        return true;
    }
    DDLogVerbose(@"[%@] Syncing started",emailAccountModel.login);
    int currentFolderIndex = 0;
    int page = 0;
    int pageSize = 20;
    CTCoreFolder *currentCoreFolder = nil;
    int updateRemoteCounter = 0;
    NSMutableDictionary* totalMessageCount = [NSMutableDictionary dictionary];
    
    while ([folders count]!=0){
        if (updateRemoteCounter++%30 == 0){
            if (![self updateRemoteMessages]){/* This can take a long time! We should update the remote messages sometimes */
                return false;
            }
        }
        NSSet* messagesBuffer = nil;
        if (self.shouldStopAsap){
            return true;
        }
        DDLogVerbose(@"[%@] ---- loop(%d folders left) ----",emailAccountModel.login, [folders count]);
        @try {
            CTCoreAccount* account = [self account];
            if (account==nil){
                return false;
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
            NSLog(@"%@",exception);
            DDLogError(@"[%@] error when getting the current folder %@",emailAccountModel.login, ((FolderModel*)[folders objectAtIndex:currentFolderIndex]).path);
            [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]]];
            return false;
        }
        if (self.shouldStopAsap){
            return true;
        }
        @try {
            int start = [((NSNumber*)[totalMessageCount objectForKey:((FolderModel*)[folders objectAtIndex:currentFolderIndex]).objectID]) intValue] - (page+1) * pageSize; 
            if (start<0) start = 0;
            int end = [((NSNumber*)[totalMessageCount objectForKey:((FolderModel*)[folders objectAtIndex:currentFolderIndex]).objectID]) intValue] - (page) * pageSize;
            if (end<0) end = 0;
            NSLog(@"page: %d (%d %d)",page, start, end);
            messagesBuffer = [currentCoreFolder messageObjectsFromIndex:start toIndex:end];
            NSLog(@"messages: %d",[messagesBuffer count]);
        }
        @catch (NSException *exception) {
            DDLogError(@"[%@] error when getting the messages for %@",emailAccountModel.login, ((FolderModel*)[folders objectAtIndex:currentFolderIndex]).path);
            [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]]];
            return false;
        }

        DDLogVerbose(@"[%@] Processing folder %@",emailAccountModel.login,currentCoreFolder.path);
        if (self.shouldStopAsap){
            return true;
        }
        for (CTCoreMessage* message in messagesBuffer){
            FolderModel* currentFolderModel = nil;
            if (self.shouldStopAsap){
                return true;
            }
            
            // get the email's folder model            
            NSFetchRequest *folderRequest = [[NSFetchRequest alloc] init];
            NSEntityDescription *folderEntity = [NSEntityDescription entityForName:[FolderModel entityName] inManagedObjectContext:self.context];
            folderRequest.entity = folderEntity;
            [folderRequest setFetchLimit:1];
            NSPredicate *folderPredicate = [NSPredicate predicateWithFormat:@"path = %@",[self decodeImapString:currentCoreFolder.path],emailAccountModel];
            [folderRequest setPredicate:folderPredicate];
            NSError* fetchFolderError = nil;
            NSArray* f = [self.context executeFetchRequest:folderRequest error:&fetchFolderError];
            [folderRequest release];
            if (fetchFolderError != nil){
                DDLogError(@"[%@] Can't get the corresponding folder",emailAccountModel.login);
                [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:fetchError forKey:ROOT_ERROR]]];
                return false;
            }else if ([f count]== 0){
                DDLogError(@"[%@] Can't get the corresponding folder",emailAccountModel.login);
                [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:nil]];
                return false;
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
            NSError* fetchError = nil;
            NSArray* matchingEmails = [[self.context executeFetchRequest:emailRequest error:&fetchError] retain];
            [emailRequest release];
            if (fetchError){
                DDLogError(@"[%@] Can't test if the message already exist",emailAccountModel.login);
                [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:fetchError forKey:ROOT_ERROR]]];
                [matchingEmails release];
                return false;   
            }
            if ([matchingEmails count]>0){
                DDLogVerbose(@"[%@] email already exist for that folder, updating ",emailAccountModel.login);
                emailModel = [matchingEmails objectAtIndex:0];
            }else{
                DDLogVerbose(@"[%@] email does not exist, creating",emailAccountModel.login);
                @try {
                    emailModel = [NSEntityDescription insertNewObjectForEntityForName:[EmailModel entityName] inManagedObjectContext:self.context];
                }
                @catch (NSException *exception) {
                    DDLogVerbose(@"[%@] error when creating the new email",emailAccountModel.login);
                    [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]]];
                    [matchingEmails release];   
                    return false;   
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
            DDLogVerbose(@"[%@] processing: %@",emailAccountModel.login,message.subject);
            emailModel.senderName = from.name;
            emailModel.senderEmail = from.email;
            emailModel.subject=message.subject;
            emailModel.sentDate = message.sentDateGMT;
            emailModel.uid = message.uid;
            emailModel.serverPath = currentCoreFolder.path;
            emailModel.read = !message.isUnread;
            emailModel.folder = currentFolderModel;
        }
        
        if (self.shouldStopAsap){
            return true;
        }
        /* If ther eis no more messages in a folder. We remove it from the list */
        if ([messagesBuffer count]==0){
            DDLogVerbose(@"[%@] no more emails in that folder, removing it from the list",emailAccountModel.login);
            [folders removeObject:[folders objectAtIndex:currentFolderIndex]];
        }
        DDLogVerbose(@"[%@] saving the context",emailAccountModel.login);
        if (![self saveContextWithError:EMAIL_MESSAGES_ERROR]){
            DDLogError(@"[%@] error when saving the context",emailAccountModel.login);
            return false;
        }
        
        [self onStateChanged];
        /* process the following 20 mails of the next folder */
        currentFolderIndex = currentFolderIndex+1;
        currentFolderIndex = currentFolderIndex % [folders count];
        DDLogVerbose(@"[%@] new index = %d (count:%d)",emailAccountModel.login, currentFolderIndex,[folders count]);
        /* Increase the current page when we loaded this one for all the folders */
        if (currentFolderIndex==0){
            page++;
            DDLogVerbose(@"[%@] switching to page %d ",emailAccountModel.login,page);
            
        }
    }
    return true;
}

-(CTCoreAccount*)account{
    if (coreAccount==nil){
        coreAccount = [[CTCoreAccount alloc] init];
    }
    if (![coreAccount isConnected]){
        @try {
            NSLog(@"%@",emailAccountModel);
            [coreAccount connectToServer:emailAccountModel.serverAddr port:[emailAccountModel.port intValue] connectionType:[emailAccountModel.conType intValue] authType:[emailAccountModel.authType intValue] login:emailAccountModel.login password:emailAccountModel.password];            
        }
        @catch (NSException *exception) {
            DDLogError(@"[%@] Connection to account failed",emailAccountModel.login);
            [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]]];
            return nil;
        }
    }
    return coreAccount;
}

-(BOOL)sync{
    emailAccountModel = (EmailAccountModel*)[[self.context objectWithID:emailAccountModelId] retain];
    DDLogVerbose(@"[%@] Sync started for account",emailAccountModel.login);
    if (![self updateLocalFolders] || ![self updateRemoteMessages] || ![self updateLocalMessages]){
        return false;
    }
    if (self.shouldStopAsap){
        return true;
    }
    DDLogVerbose(@"[%@] Sync done, saving context",emailAccountModel.login);
    if ([self saveContextWithError:EMAIL_ERROR]){
        DDLogVerbose(@"Context saved, DONE!");
        return true;
    }else{
        DDLogError(@"[%@] Error when saving the context",emailAccountModel.login);
        return false;
    }
    [emailAccountModel release];
    emailAccountModel = nil;
}

@end
