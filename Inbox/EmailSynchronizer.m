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
    DDLogVerbose(@"[%@] update local folders started",emailAccountModel.login);
    NSSet* folders = nil;
    CTCoreAccount* account = [self account];
    if (account==nil){
        return false;
    }
    
    @try {
        folders = [account allFolders];
    }
    @catch (NSException *exception) {
        DDLogError(@"[%@] error when retrieving the folders",emailAccountModel.login);
        [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_FOLDERS_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
        return false;
    }
    NSMutableSet* decodedFolders = [NSMutableSet setWithCapacity:[folders count]];
    for (NSString* folderName in folders){
        [decodedFolders addObject:[self decodeImapString:folderName]];
    }
    folders = decodedFolders;
    
    NSArray* disabledFolders = [[NSArray alloc] initWithObjects:
                                NSLocalizedString(@"folderModel.path.drafts", @"Localized Drafts folder's path en: \"Drafts\""),
                                NSLocalizedString(@"folderModel.path.sent", @"Localized Sent folder's path en: \"[Gmail]/Sent Mail\""),
                                NSLocalizedString(@"folderModel.path.notes", @"Localized Notes folder's path en: \"Notes\""),
                                @"[Gmail]",
                                nil];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[FolderModel entityName] inManagedObjectContext:context];
    request.entity = entity;
    // Delete local folders that does not exist remotely
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT(path IN %@) OR (path IN %@)", folders,disabledFolders];          
    [request setPredicate:predicate];
    NSError* fetchError = nil;
    NSArray* foldersToDelete = [context executeFetchRequest:request error:&fetchError];
        DDLogVerbose(@"[%@] Deleting folders that does not exist on the server",emailAccountModel.login);
    if (fetchError){
        DDLogError(@"[%@] Error when getting the folders to delete list",emailAccountModel.login);
        [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_FOLDERS_ERROR userInfo:[NSDictionary dictionaryWithObject:fetchError forKey:ROOT_ERROR]]];
        [disabledFolders release];
        [request release];
        return false;
    }
    for (FolderModel* folder in foldersToDelete){
        @try {
            [context deleteObject:folder];
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
        if (![disabledFolders containsObject:path]){
            DDLogVerbose(@"[%@] processing folder %@",emailAccountModel.login, path);
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"path = %@", path];          
            [request setPredicate:predicate];
            
            NSError* fetchError = nil;
            int folders = [context countForFetchRequest:request error:&fetchError];
            if (fetchError){
                DDLogError(@"[%@] Error when testing if the folder %@ exists",emailAccountModel.login, path);
                [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_FOLDERS_ERROR userInfo:[NSDictionary dictionaryWithObject:fetchError forKey:ROOT_ERROR]]];
                [disabledFolders release];
                [request release];
                return false;
            }else{
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
                }
            }
        }
    }
    [disabledFolders release];
    [request release];
    DDLogVerbose(@"[%@] folders updated, saving context",emailAccountModel.login);
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
    DDLogVerbose(@"[%@] committing local changes",emailAccountModel.login);
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailModel entityName] inManagedObjectContext:self.context];
    request.entity = entity;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"folder.path != serverPath"];
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
    for (EmailModel* email in models){
        skip = false;
        if (folder==nil || ![folder.path isEqualToString:email.folder.path]){
            [folder disconnect];
            @try {
                account = [self account];
                if (account == nil){
                    return false;
                }
                folder = [account folderWithPath:email.serverPath];
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
            DDLogVerbose(@"[%@] error when getting the matching folder on the server, skipping this email",emailAccountModel.login);
            @try {
                [folder moveMessage:email.folder.path forMessage:message];
            }
            @catch (NSException* exception) {
                [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]]];
                [request release];
                return false;
            }
            email.serverPath = folder.path;
        }
    }
    return true;
}

-(BOOL)updateLocalMessages{
    DDLogVerbose(@"[%@] Updating local messages",emailAccountModel.login);
    CTCoreFolder *currentFolder = nil;    
    NSSet* messages = nil;
    int page = 0;
    int pageSize = 20;
    
    /* get the folders model */
    NSFetchRequest *foldersRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *folderDescription = [NSEntityDescription entityForName:[FolderModel entityName] inManagedObjectContext:context];
    foldersRequest.entity =folderDescription;
    
    NSError* fetchError = nil;
    NSMutableArray* folders = [NSMutableArray arrayWithArray:[context executeFetchRequest:foldersRequest error:&fetchError]];
    DDLogVerbose(@"[%@] Getting the folders",emailAccountModel.login);
    if (fetchError){
        DDLogError(@"[%@] Error when getting folders",emailAccountModel.login);
        [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:fetchError forKey:ROOT_ERROR]]];
        [foldersRequest release];
        return false;
    }
    [foldersRequest release];
    
    /* Prepare the request used to test if a message is already is the base */
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailModel entityName] inManagedObjectContext:context];
    request.entity = entity;    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sentDate" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [sortDescriptor release];
    
    
    int folderIndex = 0;
    DDLogVerbose(@"[%@] Syncing started",emailAccountModel.login);
    while ([folders count]!=0){
        DDLogVerbose(@"[%@] ---- loop(%d folders left) ----",emailAccountModel.login, [folders count]);
        @try {
            CTCoreAccount* account = [self account];
            if (account==nil){
                return false;
            }
            
            // Check this : http://github.com/mronge/MailCore/issues/2
            [currentFolder disconnect];
            currentFolder = [account folderWithPath:((FolderModel*)[folders objectAtIndex:folderIndex]).path]; 
            [currentFolder connect];
        }
        @catch (NSException *exception) {
            DDLogError(@"[%@] error when getting the current folder %@",emailAccountModel.login, ((FolderModel*)[folders objectAtIndex:folderIndex]).path);
            [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]]];
            return false;
        }

        @try {
            NSLog(@"page: %d (%d %d)",page, page*pageSize+1, (page+1)*pageSize);

            messages = [currentFolder messageObjectsFromIndex:page*pageSize+1 toIndex:(page+1)*pageSize];
        }
        @catch (NSException *exception) {
            DDLogError(@"[%@] error when getting the messages for %@",emailAccountModel.login, ((FolderModel*)[folders objectAtIndex:folderIndex]).path);
            [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]]];
            return false;
        }

        DDLogVerbose(@"[%@] Processing folder %@",emailAccountModel.login,currentFolder.path);
        
        for (CTCoreMessage* message in messages){
            EmailModel* emailModel=nil;
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uid = %@ AND folder.path = %@", message.uid,currentFolder.path];
            [request setPredicate:predicate];
            NSError* fetchError = nil;
            NSArray* objects = [context executeFetchRequest:request error:&fetchError];
            if (fetchError){
                DDLogError(@"[%@] Can't test if the message already exist",emailAccountModel.login);
                [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:fetchError forKey:ROOT_ERROR]]];
                [request release];
                return false;   
            }
            if ([objects count]>0){
                DDLogVerbose(@"[%@] email already exist for that folder, updating ",emailAccountModel.login);
                emailModel = [objects objectAtIndex:0];
            }else{
                DDLogVerbose(@"[%@] email does not exist, creating",emailAccountModel.login);
                @try {
                    emailModel = [NSEntityDescription insertNewObjectForEntityForName:[EmailModel entityName] inManagedObjectContext:self.context];
                }
                @catch (NSException *exception) {
                    DDLogVerbose(@"[%@] error when creating the new email",emailAccountModel.login);
                    [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]]];
                    [request release];
                    return false;   
                }
            }
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
            emailModel.serverPath = ((FolderModel*)[folders objectAtIndex:folderIndex]).path;
            emailModel.folder = [folders objectAtIndex:folderIndex];
        }
        /* If ther eis no more messages in a folder. We remove it from the list */
        if ([messages count]==0){
            DDLogVerbose(@"[%@] no more emails in that folder, removing it from the list",emailAccountModel.login);
            [folders removeObject:[folders objectAtIndex:folderIndex]];
        }
        DDLogVerbose(@"[%@] saving the context",emailAccountModel.login);
        if (![self saveContextWithError:EMAIL_MESSAGES_ERROR]){
            DDLogError(@"[%@] error when saving the context",emailAccountModel.login);
            return false;
        }
        
        //[self onStateChanged];
        /* process the following 20 mails of the next folder */
        folderIndex = (folderIndex+1) % [folders count];
        DDLogVerbose(@"[%@] new index = %d",emailAccountModel.login, folderIndex);
        /* Increase the current page when we loaded this one for all the folders */
        if (folderIndex==0){
            page++;
            DDLogVerbose(@"[%@] switching to page %d ",emailAccountModel.login,page);
            
        }
    }
    [request release];
    return true;
}

-(CTCoreAccount*)account{
    if (coreAccount==nil){
        coreAccount = [[CTCoreAccount alloc] init];
    }
    if (![coreAccount isConnected]){
        @try {
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
    DDLogVerbose(@"[%@] Sync done, saving context",emailAccountModel.login);
    if ([self saveContextWithError:EMAIL_ERROR]){
        DDLogVerbose(@"Context saved, DONE!");
        return true;
    }else{
        DDLogError(@"[%@] Error when saving the context",emailAccountModel.login);
        return false;
    }
    [emailAccountModel release];
}

@end