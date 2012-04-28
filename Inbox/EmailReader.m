//
//  EmailReader.m
//  Inbox
//
//  Created by Simon Watiau on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EmailReader.h"
#import "CTCoreMessage.h"
#import "CTCoreFolder.h"
#import "CTCoreAccount.h"
#import "FolderModel.h"
#import "EmailModel.h"
#import "EmailAccountModel.h"
@implementation EmailReader

+(EmailReader*)sharedInstance{
    if (![self getInstance]){
        [self setInstance:[[[EmailReader alloc]init]autorelease]];
    }
    return (EmailReader*)[self getInstance];
}

-(int)emailsCountInInboxes:(NSError**)error{
    int returnvalue = 0;
    for (FolderModel* inbox in [self inboxes:error]){
        returnvalue+= [self emailsCountInFolder:inbox error:error];
        if (error){
            return returnvalue;
        }
    }
    return returnvalue;
}

-(int)emailsCountInFolder:(FolderModel*)folder error:(NSError**)error{
    error = nil;
    NSManagedObjectContext* context = [self sharedContext];    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailModel entityName] inManagedObjectContext:context];
    request.entity = entity;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"folder = %@", folder];          
    [request setPredicate:predicate];
    
    int count = [context countForFetchRequest:request error:error];
    [request release];
    if (error){
        return -1;
    }else{
        return count;
    }
}


-(NSArray*)foldersForAccount:(EmailAccountModel*)account error:(NSError**)error{
    error = nil;
    NSManagedObjectContext* context = [self sharedContext];    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[FolderModel entityName] inManagedObjectContext:context];
    request.entity = entity;
    [request setPropertiesToFetch:[NSArray arrayWithObject:[[entity propertiesByName] objectForKey:@"path"]]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(account = %@)", account];          
    [request setPredicate:predicate];
    
    NSArray* folders = [context executeFetchRequest:request error:error];
    [request release];
    if (error){
        return [NSArray array];
    }else{
        NSMutableArray* results = [NSMutableArray array];
        folders = [folders sortedArrayUsingSelector:@selector(compare:)];
        for (FolderModel* folder in folders){
            [results addObject:folder];
        }
        return results;
    }
}


-(void)moveEmail:(EmailModel*)email toFolder:(FolderModel *)folder error:(NSError**)error{
    if (folder.account != email.folder.account){
        *error = [NSError errorWithDomain:READER_ERROR_DOMAIN code:DATA_INVALID userInfo:[NSDictionary dictionaryWithObject:@"folder.account != email.account" forKey:ROOT_MESSAGE]];
    }
    email.folder = folder;
}

-(NSArray*)inboxes:(NSError**)error{
    *error = nil;
    NSManagedObjectContext* context = [self sharedContext];    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[FolderModel entityName] inManagedObjectContext:context];
    request.entity = entity;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"path = %@", @"INBOX"];          
    [request setPredicate:predicate];
    NSArray* inboxes = [context executeFetchRequest:request error:error];
    [request release];
    return inboxes;
}

-(EmailModel*)lastEmailFromInbox:(NSError**)error{
    NSManagedObjectContext* context = [self sharedContext];    
    NSDate *lastEmailDate = [NSDate dateWithTimeIntervalSince1970:0];
    EmailModel* returnValue = nil;
    for (FolderModel* obj in [self inboxes:error]){
        EmailModel* lastEmail = [self lastEmailFromFolder:obj error:error];
        if (*error){
            return nil;
        }
        NSDate* currentEmailDate = lastEmail.sentDate;
        if ([currentEmailDate timeIntervalSince1970] > [lastEmailDate timeIntervalSince1970]){
            lastEmailDate = currentEmailDate;
            returnValue = lastEmail;
        }
    }
    return returnValue;
}


-(EmailModel*)lastEmailFromFolder:(FolderModel *)folder error:(NSError**)error{
    *error = nil;
    NSManagedObjectContext* context = [self sharedContext];    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailModel entityName] inManagedObjectContext:context];
    request.entity = entity;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"folder = %@", folder];          
    [request setPredicate:predicate];
    NSSortDescriptor *sortBySentDate = [[NSSortDescriptor alloc] initWithKey:@"sentDate" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObjects:sortBySentDate, nil]];
    [sortBySentDate release];
    //[request setPropertiesToFetch:[entity properties]];
    
    NSArray* objects = [context executeFetchRequest:request error:error];
    [request release];
    if (*error){
        return nil;
    }else{
        if ([objects count]>0){
            EmailModel* model = [objects objectAtIndex:0];
            return model;
        }else{
            return nil;
        }
    }
}

-(void)fetchEmailBody:(EmailModel*)email error:(NSError**)error{
    NSManagedObjectContext* context = [self sharedContext];
    CTCoreAccount* account = [[CTCoreAccount alloc] init];
    @try {
        [account connectToServer:email.folder.account.serverAddr port:[email.folder.account.port intValue] connectionType:[email.folder.account.conType  intValue] authType:[email.folder.account.authType intValue] login:email.folder.account.login password:email.folder.account.password];
    }
    @catch (NSException *exception) {
        *error = [NSError errorWithDomain:READER_ERROR_DOMAIN code:FETCH_EMAIL_BODY userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
        [account release];
        return;
    }
    CTCoreFolder *inbox  = nil;
    @try {
        inbox = [account folderWithPath:email.folder.path];
    }
    @catch (NSException *exception) {
        *error = [NSError errorWithDomain:READER_ERROR_DOMAIN code:FETCH_EMAIL_BODY userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
        [account release];
        return;
    }
    
    CTCoreMessage* message = nil;
    @try {
        message = [inbox messageWithUID:email.uid];
        [message fetchBody];
    }
    @catch (NSException *exception) {
        *error = [NSError errorWithDomain:READER_ERROR_DOMAIN code:FETCH_EMAIL_BODY userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
        [account release];
        return;
    }
    email.htmlBody = [message htmlBody];
    [context save:error];
    [account release];
}


@end
