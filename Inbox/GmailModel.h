//
//  BattlefieldModel.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/13/11.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CTCoreAccount.h"
#define SYNC_STARTED @"sync started"
#define SYNC_DONE @"sync done"
#define ERROR @"error"
#define INBOX_STATE_CHANGED @"new messages"
#define FOLDERS_READY @"folders ready"
@protocol DeskProtocol;
@class EmailModel;

@interface GmailModel : NSObject{
    NSString *email;
    NSString *password;
}
@property(readonly) NSString *email;
@property(readonly) NSString *password;
-(id)initWithAccount:(NSString*)email password:(NSString*)password;
-(void)sync;
-(EmailModel*)getLastEmailFrom:(NSString*)folder;
-(BOOL)move:(EmailModel*)model to:(NSString*)folder;
-(int)emailsCountInFolder:(NSString*)folder;
-(BOOL)fetchEmailBody:(EmailModel*)model;
-(NSArray*)folders;
@end
