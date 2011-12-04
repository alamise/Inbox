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

@implementation BattlefieldModel
@synthesize delegate;

-(id)initWithEmail:(NSString*)em password:(NSString*)pwd{
    self = [self init];
    if (self) {
        email = [em retain];
        password = [pwd retain];
        shouldEnd = false;
        wordsToSort = [[NSMutableArray alloc] init];
        threadLock = [[NSLock alloc] init];
        NSThread* processThread = [[NSThread alloc] initWithTarget:self selector:@selector(process) object:nil];
        [processThread setThreadPriority:0];
        [processThread start];
        [processThread release];
    }
    return self;
}

-(void)dealloc{
    [email release];
    [password release];
    [self end];
    [threadLock release];
    [wordsToSort release];
    [super dealloc];
}

-(void)process{
    [threadLock lock];
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    CTCoreAccount *account = [[CTCoreAccount alloc] init];
    [account connectToServer:@"imap.gmail.com" port:993 connectionType:CONNECTION_TYPE_TLS authType:IMAP_AUTH_TYPE_PLAIN login:email password:password];

    // Create dest folders
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
    if (!goodExists){
        [good create];
    }
    CTCoreFolder* bad = [[CTCoreFolder alloc] initWithPath:@"bad" inAccount:account];
    if (!badExists){
        [bad create];
    }
    
    // Loop on unread messages
    CTCoreFolder *inbox = [account folderWithPath:@"INBOX"];    
    for (CTCoreMessage*  message in (NSSet*)[inbox messageObjectsFromIndex:1 toIndex:0]){
        if (message.isUnread){
            [wordsToSort addObject:message.sender.email];
            if ([wordsToSort count]==1){
                [self.delegate nextWordReady];
            }
        }
        if (shouldEnd){
            [threadLock unlock];
            return;
        }

    }
    [account release];
    [threadLock unlock];
    [pool release];
}

-(NSString*)getNextWord{
    if ([wordsToSort count]!=0){
        NSString* next = [[wordsToSort objectAtIndex:0] retain];
        [wordsToSort removeObjectAtIndex:0];
        return [next autorelease];
    }else{
        return nil;
    }
}

-(void)end{
    shouldEnd = true;
    [threadLock lock];
}

-(void)sortedWord:(NSString*)word isGood:(BOOL)isGood{

}

-(BOOL)isDone{
    return false;
}


@end
