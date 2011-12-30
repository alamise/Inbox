//
//  BattlefieldModel.m
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/13/11.
//


#import "GmailModel.h"
#import "CTCoreAccount.h"
#import "CTCoreFolder.h"
#import "CTCoreMessage.h"
#import "CTCoreAddress.h"
#import "AppDelegate.h"
#import "EmailModel.h"
#import "MailCoreTypes.h"
#import "FolderModel.h"

#define SYNC_DONE @"sync done"
#define ERROR @"error"


@interface GmailModel()
-(BOOL)saveContext:(NSManagedObjectContext*)context;
-(BOOL)updateRemoteMessages:(CTCoreAccount*)account context:(NSManagedObjectContext*)context;
-(BOOL)updateLocalMessages:(CTCoreAccount*)account context:(NSManagedObjectContext*)context;
-(BOOL)updateLocalFolders:(CTCoreAccount*)account context:(NSManagedObjectContext*)context;
@end

@implementation GmailModel
-(id)initWithAccount:(NSString*)em password:(NSString*)pwd{
    self = [self init];
    if (self) {
        email = [em retain];
        password = [pwd retain];
    }
    return self;
}

-(void)dealloc{
    [email release];
    [password release];
    [super dealloc];
}


-(BOOL)updateLocalFolders:(CTCoreAccount*)account context:(NSManagedObjectContext*)context {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[FolderModel entityName] inManagedObjectContext:context];
    request.entity = entity;
    
    for (NSString* path in [account allFolders]){
        if (![path isEqualToString:@"INBOX"] && ![path isEqualToString:@"[Gmail]"] &&![path isEqualToString:@"[Gmail]/Drafts"] && ![path isEqualToString:@"[Gmail]"] && ![path isEqualToString:@"[Gmail]/Sent Mail"] && ![path isEqualToString:@"Notes"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"path = %@", path];          
            [request setPredicate:predicate];
        
            NSError* fetchError = nil;
            int folders = [context countForFetchRequest:request error:&fetchError];
            if (fetchError){
                [[NSNotificationCenter defaultCenter] postNotificationName:ERROR object:fetchError];
                return false;
            }else{
                if (folders==0){
                    FolderModel* folderModel = [NSEntityDescription insertNewObjectForEntityForName:[FolderModel entityName] inManagedObjectContext:context];
                    folderModel.path = path;
                }
            }
        }
    }
    [request release];
    return true;
}

/*
 * Commit local changes to the server.
 * If a message is not found on the server, it's deleted locally.
 */
-(BOOL)updateRemoteMessages:(CTCoreAccount*)account context:(NSManagedObjectContext*)context{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailModel entityName] inManagedObjectContext:context];
    request.entity = entity;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"newPath != nil"];
    [request setPredicate:predicate];
    NSError* fetchError = nil;
    NSArray* models = [context executeFetchRequest:request error:&fetchError];
    [request release];
    if (fetchError!=nil){
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
        @try {
            message = [folder messageWithUID:model.uid];
        }
        @catch (NSException *exception) {
            skip = true;
        }

        // If there were an issue finding the email on the server, the message is deleted.
        if (skip){
            [context deleteObject:model];
        }else{
            @try {
                [folder copyMessage:model.newPath forMessage:message];
                [folder setFlags:CTFlagDeleted forMessage:message];
            }
            @catch (NSException* exception) {
                [[NSNotificationCenter defaultCenter] postNotificationName:ERROR object:[NSError errorWithDomain:[exception description] code:0 userInfo:nil]];
                return false;
            }
            model.path = model.newPath;
            model.newPath=nil;
        }
    }
    
    return [context save:nil];
}

-(BOOL)updateLocalMessages:(CTCoreAccount*)account context:(NSManagedObjectContext*)context{
    CTCoreFolder *inbox = [account folderWithPath:@"INBOX"];    
    NSSet* messages = nil;
    @try {
        messages = [inbox messageObjectsFromIndex:1 toIndex:0];
    }
    @catch (NSException *exception) {
        return false;
    }
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailModel entityName] inManagedObjectContext:context];
    request.entity = entity;    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sentDate" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [sortDescriptor release];
    for (CTCoreMessage*  message in messages){
        EmailModel* emailModel=nil;
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uid like %@", message.uid];
        [request setPredicate:predicate];
        NSError* fetchError = nil;
        NSArray* objects = [context executeFetchRequest:request error:&fetchError];
        if (fetchError==nil && [objects count]>0){
            emailModel = [objects objectAtIndex:0];
        }else{
            emailModel = [NSEntityDescription insertNewObjectForEntityForName:[EmailModel entityName] inManagedObjectContext:context];
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
    return [context save:nil];
}
-(void)sync {
    dispatch_async( dispatch_get_global_queue(0, 0), ^{
        NSManagedObjectContext* context = [[(AppDelegate*)[UIApplication sharedApplication].delegate getManagedObjectContext:false] retain];
        CTCoreAccount* account = [[CTCoreAccount alloc] init];
        @try {
            [account connectToServer:@"imap.gmail.com" port:993 connectionType:CONNECTION_TYPE_TLS authType:IMAP_AUTH_TYPE_PLAIN login:email password:password];
        }
        @catch (NSException *exception) {
            [account release];
            [[NSNotificationCenter defaultCenter] postNotificationName:ERROR object:[NSError errorWithDomain:[exception description] code:0 userInfo:nil]];
            return;
        }
            
        if (![self updateRemoteMessages:account context:context] || ![self updateLocalMessages:account context:context]|| ![self updateLocalFolders:account context:context]){
            [account release];
            return;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_DONE object:nil];
    });
}

-(BOOL)saveContext:(NSManagedObjectContext*)context delegate:(id<GmailModelProtocol>) delegate{
    NSError* error = nil;
    [context save:&error];
    if (error){
        [[NSNotificationCenter defaultCenter] postNotificationName:ERROR object:error];
        return false;
    }else{
        return true;
    }
}

-(EmailModel*)getLastEmailFrom:(NSString*)folder delegate:(id<GmailModelProtocol>)delegate{
    NSManagedObjectContext* context = [[(AppDelegate*)[UIApplication sharedApplication].delegate getManagedObjectContext:false] retain];    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailModel entityName] inManagedObjectContext:context];
    request.entity = entity;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(path = %@ AND newPath = nil) OR (newPath = %@)", folder, folder];          
    [request setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sentDate" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [sortDescriptor release];
    [request setPropertiesToFetch:[entity properties]];

    NSError* fetchError = nil;
    NSArray* objects = [context executeFetchRequest:request error:&fetchError];
    [context release];
    
    if (fetchError){
        [[NSNotificationCenter defaultCenter] postNotificationName:ERROR object:fetchError];
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

-(BOOL)fetchEmailBody:(EmailModel*)model{
    return false;
    /*
    @try {
        [self.account connectToServer:@"imap.gmail.com" port:993 connectionType:CONNECTION_TYPE_TLS authType:IMAP_AUTH_TYPE_PLAIN login:email password:password];
    }
    @catch (NSException *exception) {
        return false;
    }
    

    CTCoreFolder *inbox = [account folderWithPath:@"INBOX"];
    
    CTCoreMessage* message = [inbox messageWithUID:model.uid];
    [message fetchBody];
    model.htmlBody = [message htmlBody];
    [account release];
    return true;
     */
}

-(BOOL)move:(EmailModel*)model to:(NSString*)folder delegate:(id<GmailModelProtocol>) delegate{
    NSManagedObjectContext* context = [[(AppDelegate*)[UIApplication sharedApplication].delegate getManagedObjectContext:false] retain];    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailModel entityName] inManagedObjectContext:context];
    request.entity = entity;
    [request setPropertiesToFetch:[entity properties]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uid = %@", model.uid];          
    [request setPredicate:predicate];
    [request setFetchLimit:1];
    NSError* fetchError = nil;
    NSArray* objects = [context executeFetchRequest:request error:&fetchError];
    if (fetchError){
        [[NSNotificationCenter defaultCenter] postNotificationName:ERROR object:fetchError];
        return false;
    }else{
        if ([objects count]>0){
            EmailModel* linkedModel = [objects lastObject];
            linkedModel.newPath = folder;
        }
        return [self saveContext:context delegate:delegate];
    }
}

-(NSArray*)folders:(id<GmailModelProtocol>) delegate{
    NSManagedObjectContext* context = [[(AppDelegate*)[UIApplication sharedApplication].delegate getManagedObjectContext:false] retain];    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[FolderModel entityName] inManagedObjectContext:context];
    request.entity = entity;
    
    NSError* fetchError = nil;
    NSArray* folders = [context executeFetchRequest:request error:&fetchError];
    [context release];
    [request release];
    if (fetchError){
        [[NSNotificationCenter defaultCenter] postNotificationName:ERROR object:fetchError];
        return nil;
    }else{
        folders = [folders sortedArrayUsingSelector:@selector(compare:)];
        return folders;
    }

}

-(int)emailsCountInFolder:(NSString*)folder delegate:(id<GmailModelProtocol>) delegate{
    NSManagedObjectContext* context = [[(AppDelegate*)[UIApplication sharedApplication].delegate getManagedObjectContext:false] retain];    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailModel entityName] inManagedObjectContext:context];
    request.entity = entity;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"path like %@ OR newPath like %@", folder,folder];          
    [request setPredicate:predicate];
    
    NSError* fetchError = nil;
    int count = [context countForFetchRequest:request error:&fetchError];
    [context release];
    if (fetchError){
        [[NSNotificationCenter defaultCenter] postNotificationName:ERROR object:fetchError];
        return -1;
    }else{
        return count;
    }
}


@end
