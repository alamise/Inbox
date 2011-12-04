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
enum { PROCESSING, DONE };

@implementation BattlefieldModel

-(id)initWithEmail:(NSString*)em password:(NSString*)pwd{
    self = [self init];
    if (self) {
        email = [em retain];
        password = [pwd retain];
        endAsap = false;
        lock = [[NSConditionLock alloc] init];
        NSThread* processThread = [[NSThread alloc] initWithTarget:self selector:@selector(process) object:nil];
        [processThread start];
    }
    return self;
}

-(void)dealloc{
    [email release];
    [password release];
    [self end];
    [lock release];
    [super dealloc];
}

-(void)process{
    [lock lock];
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    CTCoreAccount *account = [[CTCoreAccount alloc] init];
    [account connectToServer:@"imap.gmail.com" port:993 connectionType:CONNECTION_TYPE_TLS authType:IMAP_AUTH_TYPE_PLAIN login:email password:password];
    CTCoreFolder *inbox = [account folderWithPath:@"INBOX"];
    for (CTCoreMessage*  message in (NSSet*)[inbox messageObjectsFromIndex:1 toIndex:0]){
        if (endAsap){
            [lock unlockWithCondition:DONE];
            return;
        }

        NSLog(@"%@",message.subject);
    }
    while (true){
        if (endAsap){
            [lock unlockWithCondition:DONE];
            return;
        }
    }
    
    [lock unlockWithCondition:DONE];
    [pool release];
}

-(NSString*)getNextWord{
    return @"plop";
}



-(void)end{
    endAsap = true;
    [lock lockWhenCondition:DONE];
    
}
-(void)sortedWord:(NSString*)word isGood:(BOOL)isGood{

}

-(BOOL)isDone{
    return false;
}


@end
