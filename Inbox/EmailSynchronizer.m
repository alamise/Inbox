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

@implementation EmailSynchronizer

-(id)initWithAccount:(EmailAccountModel*)accountModel{
    if (self = [super init]){
        emailAccountModel = [accountModel retain];
    }
    return self;
}

-(void)dealloc{
    [EmailAccountModel release];
    [super dealloc];
}
-(BOOL)updateLocalFolders:(CTCoreAccount*)account context:(NSManagedObjectContext*)context {
    NSSet* folders = nil;
    @try {
        folders = [account allFolders];
    }
    @catch (NSException *exception) {
        [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_FOLDERS_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
        return false;
    }
    
    NSMutableSet* decodedFolders = [NSMutableSet setWithCapacity:[folders count]];
    for (NSString* folderName in folders){
        [decodedFolders addObject:[self decodeImapString:folderName]];
    }
    folders = decodedFolders;
    
    NSArray* disabledFolders = [[NSArray alloc] initWithObjects:
                                NSLocalizedString(@"folderModel.path.inbox", @"Localized Inbox folder's path en: \"INBOX\""),
                                @"[Gmail]",
                                NSLocalizedString(@"folderModel.path.drafts", @"Localized Drafts folder's path en: \"Drafts\""),
                                NSLocalizedString(@"folderModel.path.sent", @"Localized Sent folder's path en: \"[Gmail]/Sent Mail\""),
                                NSLocalizedString(@"folderModel.path.notes", @"Localized Notes folder's path en: \"Notes\""),
                                nil];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[FolderModel entityName] inManagedObjectContext:context];
    request.entity = entity;
    // Delete local folders that does not exist remotely
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT(path IN %@)", folders];          
    [request setPredicate:predicate];
    NSError* fetchError = nil;
    NSArray* foldersToDelete = [context executeFetchRequest:request error:&fetchError];
    if (fetchError){
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
            [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_FOLDERS_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]]];
            [disabledFolders release];
            [request release];
            return false;
        }
    }
    for (NSString* path in folders){
        if (![disabledFolders containsObject:path]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"path = %@", path];          
            [request setPredicate:predicate];
            
            NSError* fetchError = nil;
            int folders = [context countForFetchRequest:request error:&fetchError];
            if (fetchError){
                [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_FOLDERS_ERROR userInfo:[NSDictionary dictionaryWithObject:fetchError forKey:ROOT_ERROR]]];
                [disabledFolders release];
                [request release];
                return false;
            }else{
                if (folders==0){
                    FolderModel* folderModel;
                    @try {
                        folderModel = [NSEntityDescription insertNewObjectForEntityForName:[FolderModel entityName] inManagedObjectContext:context];
                    }
                    @catch (NSException *exception) {
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
    
    if ([self saveContext:context errorCode:EMAIL_FOLDERS_ERROR]){
        return true;
    }else{
        return false;
    }
}


/*
 * Commit local changes to the server.
 * If a message is not found on the server, it's deleted locally.
 */
-(BOOL)updateRemoteMessages:(CTCoreAccount*)account context:(NSManagedObjectContext*)context{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailModel entityName] inManagedObjectContext:context];
    request.entity = entity;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"folder.path != serverPath"];
    [request setPredicate:predicate];
    NSError* fetchError = nil;
    NSArray* models = [context executeFetchRequest:request error:&fetchError];
    [request release];
    if (fetchError){
        [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:fetchError forKey:ROOT_ERROR]]];
        [request release];
        return false;
    }
    CTCoreFolder* folder = nil;
    BOOL skip;
    for (EmailModel* email in models){
        skip = false;
        if (folder==nil || ![folder.path isEqualToString:email.folder.path]){
            @try {
                folder = [account folderWithPath:email.serverPath];
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
                [context deleteObject:email];
            }
            @catch (NSException *exception) {
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
        }
    }
    return true;
}

-(BOOL)updateLocalMessages:(CTCoreAccount*)account context:(NSManagedObjectContext*)context{
    CTCoreFolder *inbox = nil;    
    NSSet* messages = nil;
    BOOL messagesAvailable=true;
    int page = 0;
    int pageSize = 20;
    FolderModel* inboxFolder = nil;
    
    NSFetchRequest *inboxRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *folderEntity = [NSEntityDescription entityForName:[FolderModel entityName] inManagedObjectContext:context];
    inboxRequest.entity = folderEntity;
    NSPredicate *inboxFolderPredicate = [NSPredicate predicateWithFormat:@"path == INBOX "];
    [inboxRequest setPredicate:inboxFolderPredicate];
    NSError* fetchError = nil;
    NSArray* inboxArray = [context executeFetchRequest:inboxRequest error:&fetchError];
    if (fetchError){
        [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:fetchError forKey:ROOT_ERROR]]];
        [inboxRequest release];
        return false;
    }
    [inboxRequest release];
    if ([inboxArray count]==1){
        inboxFolder = [inboxArray objectAtIndex:0];
    }else{
        [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:@"Can;t find the Inbox folder localy" forKey:ROOT_MESSAGE]]];
        return false;
    }
    
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailModel entityName] inManagedObjectContext:context];
    request.entity = entity;    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sentDate" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [sortDescriptor release];
    
    while (messagesAvailable){
        @try {
            inbox = [account folderWithPath:@"INBOX"]; 
            messages = [inbox messageObjectsFromIndex:page*pageSize+1 toIndex:(page+1)*pageSize];
            page++;
        }
        @catch (NSException *exception) {
            [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]]];
            return false;
        }
        
        for (CTCoreMessage* message in messages){
            EmailModel* emailModel=nil;
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uid = %@", message.uid];
            [request setPredicate:predicate];
            NSError* fetchError = nil;
            NSArray* objects = [context executeFetchRequest:request error:&fetchError];
            if (fetchError){
                [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:fetchError forKey:ROOT_ERROR]]];
                [request release];
                return false;   
            }
            if ([objects count]>0){
                emailModel = [objects objectAtIndex:0];
            }else{
                @try {
                    emailModel = [NSEntityDescription insertNewObjectForEntityForName:[EmailModel entityName] inManagedObjectContext:context];
                }
                @catch (NSException *exception) {
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
            emailModel.serverPath = inboxFolder.path;
            emailModel.folder = inboxFolder;
            
        }
        if ([messages count]==0){
            messagesAvailable = FALSE;
        }else{
            if (![self saveContext:context errorCode:EMAIL_MESSAGES_ERROR]){
                return false;
            }
        }
    }
    [request release];
    return true;
}


-(BOOL)sync{
    __block NSManagedObjectContext* context = nil;
    __block CTCoreAccount* account = nil;
    context = [[(AppDelegate*)[UIApplication sharedApplication].delegate newManagedObjectContext] retain];
    account = [[CTCoreAccount alloc] init];
    void (^finalize)(void) = ^{
        [context release];
        context = nil;
        [account release];
        account = nil;
    };
    @try {
        //[account connectToServer:@"imap.gmail.com" port:993 connectionType:CONNECTION_TYPE_TLS authType:IMAP_AUTH_TYPE_PLAIN login:email password:password];
        [account connectToServer:emailAccountModel.serverAddr port:emailAccountModel.port connectionType:emailAccountModel.conType authType:emailAccountModel.authType login:emailAccountModel.login password:emailAccountModel.password];
    }
    @catch (NSException *exception) {
        [self onError:[NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]]];
        finalize();
        return false;
    }
    if (![self updateLocalFolders:account context:context] || ![self updateRemoteMessages:account context:context] || ![self updateLocalMessages:account context:context]){
        finalize();
        return false;
    }
    
    if ([self saveContext:context errorCode:EMAIL_ERROR]){
        finalize();
        return true;
    }else{
        finalize();
        return false;
    }
    

}

@end
