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
    @property(nonatomic,retain) CTCoreAccount* account;
    @property(nonatomic,retain) NSManagedObjectContext *managedObjectContext;
    -(BOOL)saveContext:(NSManagedObjectContext*)context;
    -(EmailModel*)processMessage:(CTCoreMessage*)message reuseFetchRequest:(NSFetchRequest*)request;
@end

@implementation BattlefieldModel
@synthesize delegate, account, managedObjectContext;

-(id)initWithAccount:(NSString*)em password:(NSString*)pwd{
    self = [self init];
    if (self) {
        email = [em retain];
        password = [pwd retain];
        shouldEnd = false;
        emailsToBeSorted = [[NSMutableArray alloc] init];
        threadLock = [[NSLock alloc] init];
        self.managedObjectContext = [(AppDelegate*)[UIApplication sharedApplication].delegate getManagedObjectContext:false];
    }
    return self;
}

-(void)dealloc{
    self.managedObjectContext = nil;
    [email release];
    [password release];
    [self end];
    [threadLock release];
    [emailsToBeSorted release];
    [super dealloc];
}

-(BOOL)connect{
    self.account = [[[CTCoreAccount alloc] init] autorelease];
    @try {
        [self.account connectToServer:@"imap.gmail.com" port:993 connectionType:CONNECTION_TYPE_TLS authType:IMAP_AUTH_TYPE_PLAIN login:email password:password];
    }
    @catch (NSException *exception) {
        return false;
    }
    return true;
}

-(BOOL)isConnected{
    if (self.account && self.account.isConnected){
        return true;
    }else{
        return false;
    }
}


-(BOOL)syncEmails{
    if (![self isConnected]){
        return false;
    }

    // GET NEW EMAILS
    CTCoreFolder *inbox = [account folderWithPath:@"INBOX"];    
    NSSet* messages = nil;
    
    @try {
        messages = [inbox messageObjectsFromIndex:1 toIndex:0];
    }
    @catch (NSException *exception) {
        return false;
    }
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailModel entityName] inManagedObjectContext:self.managedObjectContext];
    request.entity = entity;    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sentDate" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [sortDescriptor release];
    
    for (CTCoreMessage*  message in messages){
        [self processMessage:message reuseFetchRequest:request];
    }

    if (![self saveContext:self.managedObjectContext]){
        return false;
    }
    
    
    // UPDATE 
    request.sortDescriptors=nil;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"newPath = nil"];
    [request setPredicate:predicate];
    NSError* fetchError = nil;
    NSArray* objects = [managedObjectContext executeFetchRequest:request error:&fetchError];
    if (fetchError!=nil){
        return false;
    }
    
    for (EmailModel* model in objects){
    
    
    }
    
    [request release];
}

-(void)process{
    [threadLock lock];
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    NSManagedObjectContext *localContext = [[(AppDelegate*)[UIApplication sharedApplication].delegate getManagedObjectContext:false] retain];
    
    /* offline tests : */
    /*
    for (int i=0;i<10;i++){
        EmailModel* emailModel = [[EmailModel alloc] init];
        emailModel.senderName = @"||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
        emailModel.senderEmail = @"sadsd";
        emailModel.sentDate =  [NSDate date];
        emailModel.uid = @"uid";
        emailModel.object =@"||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
        [emailsToBeSorted addObject:emailModel];

    }    
    [self.delegate emailsReady];    
    [threadLock unlock];
    [pool release];
    return;
    */
    
    

    // Loop on messages from the inbox
        [threadLock unlock];
    [managedObjectContext release];
    [pool release];
}

-(EmailModel*)processMessage:(CTCoreMessage*)message reuseFetchRequest:(NSFetchRequest*)request reuseContext:(NSManagedObjectContext*)context{
    EmailModel* emailModel=nil;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uid like %@", message.uid];
    [request setPredicate:predicate];
    NSError* fetchError = nil;
    NSArray* objects = [managedObjectContext executeFetchRequest:request error:&fetchError];
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
    return emailModel;
}

-(BOOL)saveContext:(NSManagedObjectContext*)context{
    NSError* error = nil;
    [context save:&error];
    if (error){
        [self.delegate onError:[error localizedDescription]];
        return false;
    }else{
        return true;
    }
}

-(EmailModel*)getNextEmail{
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailModel entityName] inManagedObjectContext:self.managedObjectContext];
    request.entity = entity;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"path like %@", @"INBOX"];          
    [request setPredicate:predicate];
    

    [request setFetchLimit:1];
    NSError* fetchError = nil;
    NSArray* objects = [managedObjectContext executeFetchRequest:request error:&fetchError];
    if (fetchError==nil && [objects count]>0){
        return [objects objectAtIndex:0];
    }else{
        return nil;
    }
}

-(BOOL)fetchEmailBody:(EmailModel*)model{
    CTCoreAccount *account = [[CTCoreAccount alloc] init];
    @try {
        [account connectToServer:@"imap.gmail.com" port:993 connectionType:CONNECTION_TYPE_TLS authType:IMAP_AUTH_TYPE_PLAIN login:email password:password];
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
}

-(void)end{
    shouldEnd = true;
    [threadLock lock];
}

-(void)email:(EmailModel*)model sortedTo:(folderType)folder{
    CTCoreFolder* archiveFolder = [self.account folderWithPath:@"[Gmail]/All Mail"];
    CTCoreFolder* inboxFolder = [self.account folderWithPath:@"INBOX"];
    CTCoreMessage* message = [inboxFolder messageWithUID:model.uid];
    [archiveFolder copyMessage:@"[Gmail]/All Mail" forMessage:message];
    [inboxFolder setFlags:CTFlagDeleted forMessage:message];

}

-(int)pendingEmails{
    return [emailsToBeSorted count];
}


@end
