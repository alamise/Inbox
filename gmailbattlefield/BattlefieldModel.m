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
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@end

@implementation BattlefieldModel
@synthesize delegate, fetchedResultsController, managedObjectContext;

-(id)initWithAccount:(NSString*)em password:(NSString*)pwd{
    self = [self init];
    if (self) {
        email = [em retain];
        password = [pwd retain];
        shouldEnd = false;
        emailsToBeSorted = [[NSMutableArray alloc] init];
        threadLock = [[NSLock alloc] init];
        self.managedObjectContext = [(AppDelegate*)[UIApplication sharedApplication].delegate managedObjectContext];
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
    
    /* offline tests : */
    for (int i=0;i<10;i++){
        EmailModel* emailModel = [NSEntityDescription insertNewObjectForEntityForName:[EmailModel entityName] inManagedObjectContext:managedObjectContext];
        emailModel.senderName = @"plop plop plop plop plop plop plop plop plop plop plop plop plop plop plop plop plop plop plop plop plop plop plop plop plop ";
        emailModel.senderEmail = @"sadsd";
        emailModel.sentDate =  [NSDate date];
        emailModel.uid = @"uid";
        emailModel.summary =@"summary summary summary summary summary summary summary summary summary summary summary summary summary summary summary summary summary summary summary summary summary summary summary summary summary summary summary summary summary summary ";
        [emailsToBeSorted addObject:emailModel];

    }    
    [self.delegate emailsReady];    
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"Email" inManagedObjectContext:managedObjectContext];
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entityDescription];
    NSError *error = nil;
    NSArray *array = [managedObjectContext executeFetchRequest:request error:&error];
    if (array == nil){
        NSLog(@"%@",[error description]);
    }else{
        for (EmailModel* model in array){
            NSLog(@"=%@",model.senderName);
        }
    }
    [threadLock unlock];
    [pool release];
    return;
    /* offline tests */
    
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
    // Create dest folders
    /*
    BOOL goodExists = false;
    BOOL badExists = false;
    for (NSString* folder in (NSSet*)[account allFolders]){
        if ([folder isEqualToString:@"good"]){
            goodExists=true;
        }
        if ([folder isEqualToString:@"bad"]){
            badExists=true;
        }
    }
    CTCoreFolder* good = [[CTCoreFolder alloc] initWithPath:@"good" inAccount:account];
    CTCoreFolder* bad = [[CTCoreFolder alloc] initWithPath:@"bad" inAccount:account];
    @try {
        if (!badExists){
            [bad create];
        }
        if (!goodExists){
            [good create];
        }
    }
    @catch (NSException *exception) {
        [threadLock unlock];
        [self.delegate onError:[exception description]];
        [pool release];
    }
    @finally {
        [good release];
        [bad release];
    }
    */
    
    // Loop on unread messages
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
        if (message.isUnread){
            EmailModel* emailModel = [NSEntityDescription insertNewObjectForEntityForName:[EmailModel entityName] inManagedObjectContext:managedObjectContext];
            emailModel.senderName = message.sender.name;
            emailModel.senderEmail = message.sender.email;
            emailModel.sentDate =  message.sentDateGMT;
            emailModel.uid = message.uid;
            emailModel.summary =@"summary";
            [emailsToBeSorted addObject:emailModel];
        }
        if (shouldEnd){
            [threadLock unlock];
            [pool release];
            return;
        }
    }
    [self.delegate emailsReady];
    [threadLock unlock];
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

-(void)end{
    shouldEnd = true;
    [threadLock lock];
    [managedObjectContext save:nil];
}

-(void)email:(EmailModel*)model sortedTo:(folderType)folder{
    model.sortedTo = folder;
}

-(int)pendingEmails{
    return [emailsToBeSorted count];
}


@end
