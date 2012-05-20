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

@interface FoldersSubSync ()
@end

@implementation FoldersSubSync


-(void)dealloc{    
    [super dealloc];
}

-(void)syncWithError:(NSError**)error{
    if (!error){
        NSError* err;
        error = &err;
    }
    *error = nil;
    
    // Get the remote folders
    
    NSSet* folders = nil;
    CTCoreAccount* cAccount = [self coreAccountWithError:error];
    
    if (*error){
        *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_ERROR userInfo:[NSDictionary dictionaryWithObject:@"No account set" forKey:ROOT_MESSAGE]];
        return;
    }
    
    @try {
        folders = [cAccount allFolders];
    }
    @catch (NSException *exception) {
        *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_FOLDERS_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
        return;
    }
    
    NSSet* disabledFolders = [self disabledFolders];
    NSMutableSet* foldersToProcess = [NSMutableSet setWithSet:folders];
    for (NSArray* f in disabledFolders){
        [foldersToProcess removeObject:f];
    }
    
    [self deleteFoldersExcept:foldersToProcess error:error];
    if (*error){
        return;
    }
    
    [self createOrUpdateFolders:foldersToProcess error:error];
    if (*error){
        return;
    }
    
    [self.context save:error];

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
    if (error){
        return;
    }
    
    for (FolderModel* folder in foldersToDelete){

        @try {
            [self.context deleteObject:folder];
        }
        @catch (NSException *exception) {
            *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_FOLDERS_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
            return;
        }
    }
}


-(void)createOrUpdateFolders:(NSSet*)folders error:(NSError**)error{
    if (!error){
        NSError* err = nil;
        error = &err;
    }
    *error = nil;
    for (NSString* path in folders) {
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:[FolderModel entityName] inManagedObjectContext:self.context];
        request.entity = entity;
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"path = %@ AND account = %@", path, self.accountModel];
        [request setPredicate:predicate];
        
        int folders = [self.context countForFetchRequest:request error:error];
        [request release];
        
        if (*error) {
            return;
        }
        
        if (folders == 0) {
            FolderModel* folderModel;
            @try {
                folderModel = [NSEntityDescription insertNewObjectForEntityForName:[FolderModel entityName] inManagedObjectContext:self.context];
            }
            @catch (NSException *exception) {
                *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_FOLDERS_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
                return;
            }
            folderModel.path = path;
            folderModel.account = self.accountModel;
        }
    }
    
}

@end
