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
typedef enum {
    folderArchive,
    folderInbox
} folderType;

@interface BattlefieldModel : NSObject{
    NSString *email;
    NSString *password;
    BOOL shouldEnd; // Stop the thread asap
    NSLock* threadLock; // used to wait for the processing thread
    NSMutableArray* emailsToBeSorted;
    NSMutableDictionary* sortedEmails;
    id<BFModelProtocol> delegate;
    CTCoreAccount *account;
    NSManagedObjectContext *managedObjectContext;

}


@property(nonatomic,retain) id<BFModelProtocol> delegate;
-(id)initWithAccount:(NSString*)email password:(NSString*)password;
-(BOOL)syncEmails;
-(EmailModel*)getNextEmail;
-(void)email:(EmailModel*)model sortedTo:(folderType)folder;
-(int)pendingEmails;
-(BOOL)fetchEmailBody:(EmailModel*)model;
-(BOOL)connect;
// Wait for the processing thread to finish and return
-(void)end;

@end
