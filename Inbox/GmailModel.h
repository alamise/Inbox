//
//  BattlefieldModel.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/13/11.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CTCoreAccount.h"
#import "GmailModelProtocol.h"
#define SYNC_DONE @"sync done"
#define ERROR @"error"

@protocol DeskProtocol;
@class EmailModel;

@interface GmailModel : NSObject{
    NSString *email;
    NSString *password;
}
-(id)initWithAccount:(NSString*)email password:(NSString*)password;
-(void)sync;
-(EmailModel*)getLastEmailFrom:(NSString*)folder;
-(BOOL)move:(EmailModel*)model to:(NSString*)folder;
-(int)emailsCountInFolder:(NSString*)folder;
-(BOOL)fetchEmailBody:(EmailModel*)model;
-(NSArray*)folders;
@end
