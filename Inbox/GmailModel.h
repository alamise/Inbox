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
@protocol DeskProtocol;
@class EmailModel;

@interface GmailModel : NSObject{
    NSString *email;
    NSString *password;
    id<GmailModelProtocol> delegate;
}
-(id)initWithAccount:(NSString*)email password:(NSString*)password delegate:(id<DeskProtocol>) model;
-(void)sync;
-(EmailModel*)getLastEmailFrom:(NSString*)folder;
-(void)move:(EmailModel*)model to:(NSString*)folder;
-(int)emailsCountInFolder:(NSString*)folder;
-(BOOL)fetchEmailBody:(EmailModel*)model;
-(NSArray*)folders;
@end
