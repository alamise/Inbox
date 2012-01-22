/*
 *
 * Copyright (c) 2012 Simon Watiau.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#import "GmailModel.h"
#import "CTCoreAccount.h"
#import "CTCoreFolder.h"
#import "CTCoreMessage.h"
#import "CTCoreAddress.h"
#import "AppDelegate.h"
#import "EmailModel.h"
#import "MailCoreTypes.h"
#import "FolderModel.h"
#import "RegexKitLite.h"

@interface GmailModel()
-(BOOL)saveContext:(NSManagedObjectContext*)context;
-(BOOL)updateRemoteMessages:(CTCoreAccount*)account context:(NSManagedObjectContext*)context;
-(BOOL)updateLocalMessages:(CTCoreAccount*)account context:(NSManagedObjectContext*)context;
-(BOOL)updateLocalFolders:(CTCoreAccount*)account context:(NSManagedObjectContext*)context;
-(NSString*)decodeImapString:(NSString*)input;
@end

@implementation GmailModel
@synthesize email,password,isLooping;
-(id)initWithAccount:(NSString*)em password:(NSString*)pwd{
    self = [self init];
    if (self) {
        email = [em retain];
        password = [pwd retain];
        syncLock = [[NSLock alloc] init];
        writeChangesLock = [[NSLock alloc] init];
    }
    return self;
}

-(void)dealloc{
    [email release];
    [password release];
    [super dealloc];
}


-(BOOL)updateLocalFolders:(CTCoreAccount*)account context:(NSManagedObjectContext*)context {
    NSSet* folders = nil;
    @try {
        folders = [account allFolders];
    }
    @catch (NSException *exception) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_ABORTED object:[NSError errorWithDomain:[exception description] code:0 userInfo:nil]];
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
        [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_ABORTED object:fetchError];
        [disabledFolders release];
        [request release];
        return false;
    }
    for (FolderModel* folder in foldersToDelete){
        @try {
            [context deleteObject:folder];
        }
        @catch (NSException *exception) {
            [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_ABORTED object:[NSError errorWithDomain:[exception description] code:0 userInfo:nil]];
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
                [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_ABORTED object:fetchError];
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
                        [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_ABORTED object:[NSError errorWithDomain:[exception description] code:0 userInfo:nil]];
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
    
    if ([self saveContext:context]){
        [[NSNotificationCenter defaultCenter] postNotificationName:FOLDERS_READY object:nil];
        return true;
    }else{
        return false;
    }
}


-(NSString*)decodeImapString:(NSString*)input{
    NSMutableDictionary* translationTable = [[NSMutableDictionary alloc] init];
    [translationTable setObject:@"&" forKey:@"&-"];
    [translationTable setObject:@"é" forKey:@"&AOk-"];
    [translationTable setObject:@"â" forKey:@"&AOI-"];
    [translationTable setObject:@"à" forKey:@"&AOA-"];
    [translationTable setObject:@"è" forKey:@"&AOg"];
    [translationTable setObject:@"ç" forKey:@"&AOc"];
    [translationTable setObject:@"ù" forKey:@"&APk"];
    [translationTable setObject:@"ê" forKey:@"&AOo"];
    [translationTable setObject:@"î" forKey:@"&AO4"];
    [translationTable setObject:@"ó" forKey:@"&APM"];
    [translationTable setObject:@"ñ" forKey:@"&APE"];
    [translationTable setObject:@"á" forKey:@"&AOE"];
    [translationTable setObject:@"ô" forKey:@"&APQ"];                   
    [translationTable setObject:@"É" forKey:@"&AMk"];
    [translationTable setObject:@"ë" forKey:@"&AOs"];
    
    for (NSString* key in [translationTable allKeys]){
        input = [input stringByReplacingOccurrencesOfString:key withString:[translationTable objectForKey:key]];
    }
    return input;
}


/*
 * Commit local changes to the server.
 * If a message is not found on the server, it's deleted locally.
 */
-(BOOL)updateRemoteMessages:(CTCoreAccount*)account context:(NSManagedObjectContext*)context{
    if(![writeChangesLock tryLock]){
        return true;
    }
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailModel entityName] inManagedObjectContext:context];
    request.entity = entity;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"newPath != nil"];
    [request setPredicate:predicate];
    NSError* fetchError = nil;
    NSArray* models = [context executeFetchRequest:request error:&fetchError];
    [request release];
    if (fetchError){
        [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_ABORTED object:fetchError];
        [request release];
        [writeChangesLock unlock];
        return false;
    }
    CTCoreFolder* folder = nil;
    BOOL skip;
    for (EmailModel* model in models){
        skip = false;
        if (folder==nil || ![folder.path isEqualToString:model.path]){
            @try {
                folder = [account folderWithPath:model.path];
            }
            @catch (NSException *exception) {
                skip = true;
            }
        }
        
        CTCoreMessage* message;
        if (!skip){
            @try {
                message = [folder messageWithUID:model.uid];
            }
            @catch (NSException *exception) {
                skip = true;
            }
        }

        // If there were an issue finding the email on the server, the message is deleted.
        if (skip){
            @try {
                [context deleteObject:model];
            }
            @catch (NSException *exception) {
                [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_ABORTED object:[NSError errorWithDomain:[exception description] code:0 userInfo:nil]];
                [request release];
                [writeChangesLock unlock];
                return false; 
            }
        }else{
            @try {
                [folder copyMessage:model.newPath forMessage:message];
                [folder setFlags:CTFlagDeleted forMessage:message];
            }
            @catch (NSException* exception) {
                [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_ABORTED object:[NSError errorWithDomain:[exception description] code:0 userInfo:nil]];
                [request release];
                [writeChangesLock unlock];
                return false;
            }
            model.path = model.newPath;
            model.newPath=nil;
        }
    }
    [writeChangesLock unlock];
    return true;
}

-(BOOL)updateLocalMessages:(CTCoreAccount*)account context:(NSManagedObjectContext*)context{
    CTCoreFolder *inbox = nil;    
    NSSet* messages = nil;
    BOOL messagesAvailable=true;
    int page = 0;
    int pageSize = 20;
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
            [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_ABORTED object:[NSError errorWithDomain:[exception description] code:0 userInfo:nil]];
            return false;
        }
        
        for (CTCoreMessage* message in messages){
            EmailModel* emailModel=nil;
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uid = %@", message.uid];
            [request setPredicate:predicate];
            NSError* fetchError = nil;
            NSArray* objects = [context executeFetchRequest:request error:&fetchError];
            if (fetchError){
                [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_ABORTED object:fetchError];
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
                    [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_ABORTED object:[NSError errorWithDomain:[exception description] code:0 userInfo:nil]];
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
            emailModel.path = inbox.path;
        }
        if ([messages count]==0){
            messagesAvailable = FALSE;
        }else{
            if (![self saveContext:context]){
                return false;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:INBOX_STATE_CHANGED object:nil];
        }
    }
    [request release];
    return true;
}

-(BOOL)isSyncing{
    if([syncLock tryLock]){
        [syncLock unlock];
        return NO;
    }else{
        return YES;
    }
}

-(void)sync{
    dispatch_async( dispatch_get_global_queue(0, 0), ^{
        if(![syncLock tryLock]){
            return;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_STARTED object:nil];
        NSManagedObjectContext* context = [[(AppDelegate*)[UIApplication sharedApplication].delegate managedObjectContext:false] retain];
        CTCoreAccount* account = [[CTCoreAccount alloc] init];
        @try {
            [account connectToServer:@"imap.gmail.com" port:993 connectionType:CONNECTION_TYPE_TLS authType:IMAP_AUTH_TYPE_PLAIN login:email password:password];
        }
        @catch (NSException *exception) {
            [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_ABORTED object:[NSError errorWithDomain:[exception description] code:0 userInfo:nil]];
            [account release];
            [context release];
            [syncLock unlock];
            return;
        }
        if (![self updateLocalFolders:account context:context] || ![self updateRemoteMessages:account context:context] || ![self updateLocalMessages:account context:context]){
            [account release];
            [context release];
            [syncLock unlock];
            return;
        }
        if ([self saveContext:context]){
            [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_DONE object:nil];
        }        
        [syncLock unlock];
    });
}

-(BOOL)saveContext:(NSManagedObjectContext*)context{
    NSError* error = nil;
    [context save:&error];
    if (error){
        [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_ABORTED object:error];
        return false;
    }else{
        return true;
    }
}

-(EmailModel*)getLastEmailFrom:(NSString*)folder{
    NSManagedObjectContext* context = [[(AppDelegate*)[UIApplication sharedApplication].delegate managedObjectContext:true] retain];    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailModel entityName] inManagedObjectContext:context];
    request.entity = entity;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(path = %@ AND newPath = nil) OR (newPath = %@)", folder, folder];          
    [request setPredicate:predicate];
    NSSortDescriptor *sortBySentDate = [[NSSortDescriptor alloc] initWithKey:@"sentDate" ascending:NO];
    NSSortDescriptor *sortBySkippedIndex = [[NSSortDescriptor alloc] initWithKey:@"skippedIndex" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObjects:sortBySkippedIndex, sortBySentDate, nil]];
    [sortBySentDate release];
    [sortBySkippedIndex release];
    [request setPropertiesToFetch:[entity properties]];

    NSError* fetchError = nil;
    NSArray* objects = [context executeFetchRequest:request error:&fetchError];
    [context release];
    [request release];
    if (fetchError){
        [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_ABORTED object:fetchError];
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


-(void)stopSync{
    shouldStopSync = YES;
}

-(BOOL)fetchEmailBody:(EmailModel*)model{
    CTCoreAccount* account = [[CTCoreAccount alloc] init];
    @try {
        [account connectToServer:@"imap.gmail.com" port:993 connectionType:CONNECTION_TYPE_TLS authType:IMAP_AUTH_TYPE_PLAIN login:email password:password];
    }
    @catch (NSException *exception) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_ABORTED object:[NSError errorWithDomain:[exception description] code:0 userInfo:nil]];
        [account release];
        return false;
    }
    CTCoreFolder *inbox  = nil;
    @try {
        inbox = [account folderWithPath:model.path];
    }
    @catch (NSException *exception) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_ABORTED object:[NSError errorWithDomain:[exception description] code:0 userInfo:nil]];
        [account release];
        return false;
    }
    
    CTCoreMessage* message = nil;
    @try {
        message = [inbox messageWithUID:model.uid];
        [message fetchBody];
    }
    @catch (NSException *exception) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_ABORTED object:[NSError errorWithDomain:[exception description] code:0 userInfo:nil]];
        [account release];
        return false;
    }
    model.htmlBody = [message htmlBody];
    [account release];
    return true;
}

-(void)move:(EmailModel*)model to:(NSString*)folder{
    if ([folder isEqualToString:@"INBOX"]){
        model.skippedIndex=[NSNumber numberWithInt:[model.skippedIndex intValue]+1];
    }else{
        model.newPath = folder;
    }
    return;
}


-(void)updateRemoteMessagesAsync{
    if ([writeChangesLock tryLock]){
        [writeChangesLock unlock];
        CTCoreAccount* account = [[CTCoreAccount alloc] init];
        @try {
            [account connectToServer:@"imap.gmail.com" port:993 connectionType:CONNECTION_TYPE_TLS authType:IMAP_AUTH_TYPE_PLAIN login:email password:password];
        }
        @catch (NSException *exception) {
            return;
        }
        NSManagedObjectContext* context = [[(AppDelegate*)[UIApplication sharedApplication].delegate managedObjectContext:true] retain];
        [self updateRemoteMessages:account context:context];
        [context release];
    }

}

-(NSArray*)folders{
    NSManagedObjectContext* context = [[(AppDelegate*)[UIApplication sharedApplication].delegate managedObjectContext:true] retain];    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[FolderModel entityName] inManagedObjectContext:context];
    request.entity = entity;
    
    NSError* fetchError = nil;
    NSArray* folders = [context executeFetchRequest:request error:&fetchError];
    [context release];
    [request release];
    if (fetchError){
        [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_ABORTED object:fetchError];
        return nil;
    }else{
        folders = [folders sortedArrayUsingSelector:@selector(compare:)];
        return folders;
    }
}

-(int)emailsCountInFolder:(NSString*)folder{
    NSManagedObjectContext* context = [[(AppDelegate*)[UIApplication sharedApplication].delegate managedObjectContext:true] retain];    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailModel entityName] inManagedObjectContext:context];
    request.entity = entity;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(path = %@ AND newPath = nil) OR (newPath = %@)", folder,folder];          
    [request setPredicate:predicate];
    
    NSError* fetchError = nil;
    int count = [context countForFetchRequest:request error:&fetchError];
    [context release];
    if (fetchError){
        [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_ABORTED object:fetchError];
        [request release];
        [context release];
        return -1;
    }else{
        return count;
    }
}


@end
