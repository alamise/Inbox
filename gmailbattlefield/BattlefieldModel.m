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

@interface BattlefieldModel()

@end

@implementation BattlefieldModel
@synthesize delegate;

-(id)initWithAccount:(NSString*)em password:(NSString*)pwd{
    self = [self init];
    if (self) {
        email = [em retain];
        password = [pwd retain];
        shouldEnd = false;
        emailsToBeSorted = [[NSMutableArray alloc] init];
        threadLock = [[NSLock alloc] init];
    }
    return self;
}

-(void)dealloc{
    [email release];
    [password release];
    [self end];
    [threadLock release];
    [emailsToBeSorted release];
    [super dealloc];
}

-(void)startProcessing{
    if (![threadLock tryLock]){
        return;
    }
    [threadLock unlock];
    NSThread* processThread = [[NSThread alloc] initWithTarget:self selector:@selector(process) object:nil];
    [processThread setThreadPriority:0];
    [processThread start];
    [processThread release];
}

-(void)process{
    [threadLock lock];
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    NSManagedObjectContext *managedObjectContext = [[(AppDelegate*)[UIApplication sharedApplication].delegate getManagedObjectContext:false] retain];
    
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
    CTCoreAccount *account = [[[CTCoreAccount alloc] init] autorelease];
    @try {
        [account connectToServer:@"imap.gmail.com" port:993 connectionType:CONNECTION_TYPE_TLS authType:IMAP_AUTH_TYPE_PLAIN login:email password:password];
    }
    @catch (NSException *exception) {
        [threadLock unlock];
        [self.delegate onError:[exception description]];
        [pool release];
        return;
    }
    
    // Loop on messages from the inbox
    CTCoreFolder *inbox = [account folderWithPath:@"INBOX"];    
    NSSet* messages = nil;
    
    @try {
        messages = [inbox messageObjectsFromIndex:1 toIndex:0];
    }
    @catch (NSException *exception) {
        [threadLock unlock];
        [self.delegate onError:[exception description]];
        [pool release];
    }

    for (CTCoreMessage*  message in messages){
        EmailModel* emailModel=nil;
        
        /* Create or get the email model */
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailModel entityName] inManagedObjectContext:managedObjectContext];
        request.entity = entity;
        request.propertiesToFetch = [NSArray arrayWithObject:[[entity propertiesByName] objectForKey:@"uid"]];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uid like %@", message.uid];          
        [request setPredicate:predicate];
        NSError* fetchError = nil;
        NSArray* objects = [managedObjectContext executeFetchRequest:request error:&fetchError];
        if (fetchError==nil && [objects count]>0){
            emailModel = [objects objectAtIndex:0];
        }else{
            emailModel = [NSEntityDescription insertNewObjectForEntityForName:[EmailModel entityName] inManagedObjectContext:managedObjectContext];
        }
        NSEnumerator* enumerator = [message.from objectEnumerator];
        CTCoreAddress* from;
        // The "sender" field is not valid (the name is wrong sometimes)
        if ([message.from count]>0){
            from = [enumerator nextObject];
        }else{
            from = message.sender;
        }
        
        [request release];
        emailModel.senderName = from.name;
        emailModel.senderEmail = from.email;
        emailModel.subject=message.subject;
        [emailsToBeSorted addObject:emailModel];
        
        if (shouldEnd){
            [threadLock unlock];
            [pool release];
            return;
        }
    }
    [self.delegate emailsReady];
    [threadLock unlock];
    [managedObjectContext release];
    [pool release];
}

-(EmailModel*)getNextEmail{
    if ([emailsToBeSorted count]!=0){
        EmailModel* next = [[emailsToBeSorted objectAtIndex:0] retain];
        [emailsToBeSorted removeObjectAtIndex:0];
        return [next autorelease];
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
    model.sortedTo = folder;
}

-(int)pendingEmails{
    return [emailsToBeSorted count];
}


@end
