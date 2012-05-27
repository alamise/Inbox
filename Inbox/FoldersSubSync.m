//
//  FoldersSynchronizer.m
//  Inbox
//
//  Created by Simon Watiau on 5/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FoldersSubSync.h"
#import <CoreData/CoreData.h>
#import "FolderModel.h"
#import "EmailSynchronizer.h"
#import "CTCoreAccount.h"
#import "EmailAccountModel.h"
#import "DDLog.h"
#define ddLogLevel LOG_LEVEL_VERBOSE
@interface FoldersSubSync ()
@end

@implementation FoldersSubSync


-(void)dealloc{    
    [super dealloc];
}

-(void)syncWithError:(NSError**)error{
    if ( self.shouldStopAsap ) return ;/* STOP ASAP */
    DDLogVerbose(@"syncing folders");
    if (!error){
        NSError* err;
        error = &err;
    }
    *error = nil;
    
    // Get the remote folders
    
    NSSet* folders = nil;
    CTCoreAccount* cAccount = [self coreAccountWithError:error];
    if ( self.shouldStopAsap ) return ;/* STOP ASAP */
    if (*error){
        *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_ERROR userInfo:[NSDictionary dictionaryWithObject:@"No account set" forKey:ROOT_MESSAGE]];
        DDLogError(@"syncing folders ended with an error");
        return;
    }
    
    @try {
        folders = [cAccount allFolders];
    }
    @catch (NSException *exception) {
        *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_FOLDERS_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
        DDLogError(@"syncing folders ended with an error");
        return;
    }
    if ( self.shouldStopAsap ) return ;/* STOP ASAP */
    NSSet* disabledFolders = [self disabledFolders];
    NSMutableSet* foldersToProcess = [NSMutableSet setWithSet:folders];
    for ( NSArray* f in disabledFolders ) {
        [foldersToProcess removeObject:f];
    }
    
    [self deleteFoldersExcept:foldersToProcess error:error];
    if (*error){
        DDLogError(@"syncing folders ended with an error");
        return;
    }
    
    [self createOrUpdateFolders:foldersToProcess error:error];
    if (*error){
        DDLogError(@"syncing folders ended with an error");
        return;
    }
    [self.context save:error];
    if (*error){
        *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_FOLDERS_ERROR userInfo:[NSDictionary dictionaryWithObject:*error forKey:ROOT_ERROR]];
        DDLogError(@"syncing folders ended with an error");
        return;
    }
    DDLogVerbose(@"folders sync successful");
}

-(NSSet*)disabledFolders {
    return [[NSSet alloc] initWithObjects:
            NSLocalizedString(@"folderModel.path.drafts", @"Localized Drafts folder's path en: \"Drafts\""),
            NSLocalizedString(@"folderModel.path.sent", @"Localized Sent folder's path en: \"[Gmail]/Sent Mail\""),
            NSLocalizedString(@"folderModel.path.notes", @"Localized Notes folder's path en: \"Notes\""),
            @"[Gmail]",
            nil];
}


-(void)deleteFoldersExcept:(NSSet*)foldersToKeep error:(NSError**)error{
    if ( self.shouldStopAsap ) return ;/* STOP ASAP */
    if (!error){
        NSError* err = nil;
        error = &err;
    }
    *error = nil;

    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[FolderModel entityName] inManagedObjectContext:self.context];
    request.entity = entity;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT(path IN %@) AND account = %@", foldersToKeep, self.accountModel];          
    [request setPredicate:predicate];
    NSArray* foldersToDelete = [self.context executeFetchRequest:request error:error];
    [request release];
    
    if (*error) {
        *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_FOLDERS_ERROR userInfo:[NSDictionary dictionaryWithObject:*error forKey:ROOT_ERROR]];
        return;
    }
    
    for (FolderModel* folder in foldersToDelete) {
        if ( self.shouldStopAsap ) return ;/* STOP ASAP */
        DDLogInfo(@"Deleting the local folder: %@",folder.path);
        @try {
            [self.context deleteObject:folder];
        }
        @catch (NSException *exception) {
            *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_FOLDERS_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
            DDLogError(@"Error when deleting a folder");
            return;
        }
    }
}


-(void)createOrUpdateFolders:(NSSet*)folders error:(NSError**)error{
    if ( self.shouldStopAsap ) return ;/* STOP ASAP */
    if (!error){
        NSError* err = nil;
        error = &err;
    }
    *error = nil;
    for (NSString* path in folders) {
        if ( self.shouldStopAsap ) return ;/* STOP ASAP */
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:[FolderModel entityName] inManagedObjectContext:self.context];
        request.entity = entity;
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"path = %@ AND account = %@", path, self.accountModel];
        [request setPredicate:predicate];
        
        int folders = [self.context countForFetchRequest:request error:error];
        [request release];
        if ( self.shouldStopAsap ) return ;/* STOP ASAP */
        if (*error) {
            *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_FOLDERS_ERROR userInfo:[NSDictionary dictionaryWithObject:*error forKey:ROOT_ERROR]];
            DDLogError(@"error when creating/updating local folders");
            return;
        }
        
        if (folders == 0) {
            DDLogInfo(@"Creating the folder: %@", path);
            FolderModel* folderModel;
            @try {
                folderModel = [NSEntityDescription insertNewObjectForEntityForName:[FolderModel entityName] inManagedObjectContext:self.context];
            }
            @catch (NSException *exception) {
                *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_FOLDERS_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
                    DDLogError(@"error when creating a new local folder");
                return;
            }
            folderModel.path = path;
            folderModel.account = self.accountModel;
        }
    }
}

@end
