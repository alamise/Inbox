//
//  BattlefieldModel.m
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/13/11.
//


#import "BattlefieldModel.h"
#import "CTCoreAccount.h"
#import "CTCoreFolder.h"
#import "CTCoreMessage.h"
#import "CTCoreAddress.h"
#import "AppDelegate.h"
#import "EmailModel.h"
#import "MailCoreTypes.h"
@interface BattlefieldModel()
    -(BOOL)saveContext:(NSManagedObjectContext*)context;
    -(EmailModel*)processMessage:(CTCoreMessage*)message reuseFetchRequest:(NSFetchRequest*)request reuseContext:(NSManagedObjectContext*)context path:(NSString*)path;
@end

@implementation BattlefieldModel

-(id)initWithAccount:(NSString*)em password:(NSString*)pwd delegate:(id<BFModelProtocol>)d{
    self = [self init];
    if (self) {
        delegate = [d retain];
        email = [em retain];
        password = [pwd retain];
        managedObjectContext = [[(AppDelegate*)[UIApplication sharedApplication].delegate getManagedObjectContext:true] retain];
    }
    return self;
}

-(void)dealloc{
    [managedObjectContext release];
    [email release];
    [password release];
    [delegate release];
    
    [super dealloc];
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
                return false;
            }
            model.path = model.newPath;
            model.newPath=nil;
        }
    }

    return [self saveContext:context];
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
    return [self saveContext:context];
}

-(void)sync{
    dispatch_queue_t currentQueue =  dispatch_get_current_queue();
    dispatch_async( dispatch_get_global_queue(0, 0), ^{
        NSManagedObjectContext* context = [[(AppDelegate*)[UIApplication sharedApplication].delegate getManagedObjectContext:false] retain];
        CTCoreAccount* account = [[CTCoreAccount alloc] init];
        @try {
            [account connectToServer:@"imap.gmail.com" port:993 connectionType:CONNECTION_TYPE_TLS authType:IMAP_AUTH_TYPE_PLAIN login:email password:password];
        }
        @catch (NSException *exception) {
            [account release];
            [delegate onError:@""];
            return;
        }
        
        for (NSString* forl in [account allFolders]){
            NSLog(@"%@",forl);
        }
        
        if (![self updateRemoteMessages:account context:context] || ![self updateLocalMessages:account context:context]){
            [account release];
            [delegate onError:@""];
            return;
        }
    
        dispatch_async(currentQueue, ^{
            [delegate syncDone];
        });
    });
}

-(BOOL)saveContext:(NSManagedObjectContext*)context{
    NSError* error = nil;
    [context save:&error];
    if (error){
        [delegate onError:[error localizedDescription]];
        return false;
    }else{
        return true;
    }
}

-(EmailModel*)getLastEmailFrom:(NSString*)folder{
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
    if (fetchError==nil && [objects count]>0){
        EmailModel* model = [objects objectAtIndex:0];
        return model;
    }else{
        return nil;
    }
    [context release];
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

-(void)move:(EmailModel*)model to:(NSString*)folder{
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

    if (fetchError==nil && [objects count]>0){
        EmailModel* linkedModel = [objects lastObject];
        linkedModel.newPath = folder;
    }
    [self saveContext:context];
}

-(int)emailsCountInFolder:(NSString*)folder{

    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailModel entityName] inManagedObjectContext:managedObjectContext];
    request.entity = entity;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"path like %@ OR newPath like %@", folder,folder];          
    [request setPredicate:predicate];
    
    NSError* fetchError = nil;
    int count = [managedObjectContext countForFetchRequest:request error:&fetchError];
    if (fetchError==nil){
        return count;
    }else{
        [delegate onError:@"Cant count emails"];
        return 0;
    }
}


@end
