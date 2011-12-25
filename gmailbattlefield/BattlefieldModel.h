//
//  BattlefieldModel.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/13/11.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CTCoreAccount.h"
#import "BFModelProtocol.h"
@class EmailModel;

@interface BattlefieldModel : NSObject{
    NSString *email;
    NSString *password;
    id<BFModelProtocol> delegate;
    NSManagedObjectContext *managedObjectContext;
}
-(id)initWithAccount:(NSString*)email password:(NSString*)password delegate:(id<BFModelProtocol>) model;
-(void)sync;
-(EmailModel*)getLastEmailFrom:(NSString*)folder;
-(void)move:(EmailModel*)model to:(NSString*)folder;
-(int)emailsCountInFolder:(NSString*)folder;
-(BOOL)fetchEmailBody:(EmailModel*)model;
@end
