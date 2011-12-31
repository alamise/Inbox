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

@interface GmailModel()
-(BOOL)saveContext:(NSManagedObjectContext*)context;
-(BOOL)updateRemoteMessages:(CTCoreAccount*)account context:(NSManagedObjectContext*)context;
-(BOOL)updateLocalMessages:(CTCoreAccount*)account context:(NSManagedObjectContext*)context;
-(BOOL)updateLocalFolders:(CTCoreAccount*)account context:(NSManagedObjectContext*)context;
@end

@implementation GmailModel
@synthesize email,password;
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
    NSSet* folders = nil;
    @try {
        folders = [account allFolders];
    }
    @catch (NSException *exception) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ERROR object:[NSError errorWithDomain:[exception description] code:0 userInfo:nil]];
        return false;
    }
    NSArray* disabledFolders = [[NSArray alloc] initWithObjects:@"INBOX",@"[Gmail]",@"[Gmail]/Drafts",@"[Gmail]/Sent Mail",@"Notes", nil];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[FolderModel entityName] inManagedObjectContext:context];
    request.entity = entity;
    
    // Delete local folders that does not exist remotely
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT(path IN %@)", folders];          
    [request setPredicate:predicate];
    NSError* fetchError = nil;
    NSArray* foldersToDelete = [context executeFetchRequest:request error:&fetchError];
    if (fetchError){
        [[NSNotificationCenter defaultCenter] postNotificationName:ERROR object:fetchError];
        [disabledFolders release];
        [request release];
        return false;
    }
    for (FolderModel* folder in foldersToDelete){
        @try {
            [context deleteObject:folder];
        }
        @catch (NSException *exception) {
            [[NSNotificationCenter defaultCenter] postNotificationName:ERROR object:[NSError errorWithDomain:[exception description] code:0 userInfo:nil]];
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
                [[NSNotificationCenter defaultCenter] postNotificationName:ERROR object:fetchError];
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
                        [[NSNotificationCenter defaultCenter] postNotificationName:ERROR object:[NSError errorWithDomain:[exception description] code:0 userInfo:nil]];
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
    if (fetchError){
        [[NSNotificationCenter defaultCenter] postNotificationName:ERROR object:fetchError];
        [request release];
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
                [[NSNotificationCenter defaultCenter] postNotificationName:ERROR object:[NSError errorWithDomain:[exception description] code:0 userInfo:nil]];
                [request release];
                return false; 
            }
        }else{
            @try {
                [folder copyMessage:model.newPath forMessage:message];
                [folder setFlags:CTFlagDeleted forMessage:message];
            }
            @catch (NSException* exception) {
                [[NSNotificationCenter defaultCenter] postNotificationName:ERROR object:[NSError errorWithDomain:[exception description] code:0 userInfo:nil]];
                [request release];
                return false;
            }
            model.path = model.newPath;
            model.newPath=nil;
        }
    }
    
    return true;
}

-(BOOL)updateLocalMessages:(CTCoreAccount*)account context:(NSManagedObjectContext*)context{
    CTCoreFolder *inbox = nil;    
    NSSet* messages = nil;
    BOOL messagesAvailable=true;
    int page = 0;
    int pageSize = 5;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailModel entityName] inManagedObjectContext:context];
    request.entity = entity;    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sentDate" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [sortDescriptor release];
    
    while (messagesAvailable){
        @try {
            inbox = [account folderWithPath:@"INBOX"]; 
            messages = [inbox messageObjectsFromIndex:page*pageSize+1 toIndex:page*pageSize];
        }
        @catch (NSException *exception) {
            [[NSNotificationCenter defaultCenter] postNotificationName:ERROR object:[NSError errorWithDomain:[exception description] code:0 userInfo:nil]];
            return false;
        }
        
        for (CTCoreMessage* message in messages){
            EmailModel* emailModel=nil;
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uid = %@", message.uid];
            [request setPredicate:predicate];
            NSError* fetchError = nil;
            NSArray* objects = [context executeFetchRequest:request error:&fetchError];
            if (fetchError){
                [[NSNotificationCenter defaultCenter] postNotificationName:ERROR object:fetchError];
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
                    [[NSNotificationCenter defaultCenter] postNotificationName:ERROR object:[NSError errorWithDomain:[exception description] code:0 userInfo:nil]];
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
-(void)sync {
    [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_STARTED object:nil];
    dispatch_async( dispatch_get_global_queue(0, 0), ^{
        NSManagedObjectContext* context = [[(AppDelegate*)[UIApplication sharedApplication].delegate managedObjectContext:false] retain];
        CTCoreAccount* account = [[CTCoreAccount alloc] init];
        @try {
            [account connectToServer:@"imap.gmail.com" port:993 connectionType:CONNECTION_TYPE_TLS authType:IMAP_AUTH_TYPE_PLAIN login:email password:password];
        }
        @catch (NSException *exception) {
            [[NSNotificationCenter defaultCenter] postNotificationName:ERROR object:[NSError errorWithDomain:[exception description] code:0 userInfo:nil]];
            [account release];
            [context release];
            return;
        }
            
        if (![self updateLocalFolders:account context:context] || ![self updateRemoteMessages:account context:context] || ![self updateLocalMessages:account context:context]){
            [account release];
            [context release];
            return;
        }
        if ([self saveContext:context]){
            [[NSNotificationCenter defaultCenter] postNotificationName:SYNC_DONE object:nil];
        }
        
    });
}

-(BOOL)saveContext:(NSManagedObjectContext*)context{
    NSError* error = nil;
    [context save:&error];
    if (error){
        [[NSNotificationCenter defaultCenter] postNotificationName:ERROR object:error];
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
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sentDate" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [sortDescriptor release];
    [request setPropertiesToFetch:[entity properties]];

    NSError* fetchError = nil;
    NSArray* objects = [context executeFetchRequest:request error:&fetchError];
    [context release];
    [request release];
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
    CTCoreAccount* account = [[CTCoreAccount alloc] init];
    @try {
        [account connectToServer:@"imap.gmail.com" port:993 connectionType:CONNECTION_TYPE_TLS authType:IMAP_AUTH_TYPE_PLAIN login:email password:password];
    }
    @catch (NSException *exception) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ERROR object:[NSError errorWithDomain:[exception description] code:0 userInfo:nil]];
        [account release];
        return false;
    }
    CTCoreFolder *inbox  = nil;
    @try {
        inbox = [account folderWithPath:model.path];
    }
    @catch (NSException *exception) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ERROR object:[NSError errorWithDomain:[exception description] code:0 userInfo:nil]];
        [account release];
        return false;
    }
    
    CTCoreMessage* message = nil;
    @try {
        message = [inbox messageWithUID:model.uid];
        [message fetchBody];
    }
    @catch (NSException *exception) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ERROR object:[NSError errorWithDomain:[exception description] code:0 userInfo:nil]];
        [account release];
        return false;
    }
    model.htmlBody = [message htmlBody];
    [account release];
    return true;
}

-(BOOL)move:(EmailModel*)model to:(NSString*)folder{
    [model awakeFromFetch];
   
        model.newPath = folder;        
        return true;
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
        [[NSNotificationCenter defaultCenter] postNotificationName:ERROR object:fetchError];
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
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"path like %@ OR newPath like %@", folder,folder];          
    [request setPredicate:predicate];
    
    NSError* fetchError = nil;
    int count = [context countForFetchRequest:request error:&fetchError];
    [context release];
    if (fetchError){
        [[NSNotificationCenter defaultCenter] postNotificationName:ERROR object:fetchError];
        [request release];
        [context release];
        return -1;
    }else{
        return count;
    }
}


@end
