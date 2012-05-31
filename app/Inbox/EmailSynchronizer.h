#import <Foundation/Foundation.h>
#import "Synchronizer.h"
@class EmailAccountModel,CTCoreAccount,NSManagedObjectID;
@interface EmailSynchronizer : Synchronizer{
    EmailAccountModel* emailAccountModel;
    CTCoreAccount* coreAccount;
    NSManagedObjectID* emailAccountModelId;
    NSMutableArray *subSyncs;
}
-(id)initWithAccountId:(NSManagedObjectID*)accountId;
@property(nonatomic,readonly,retain) EmailAccountModel* emailAccountModel;
+(NSString*)decodeImapString:(NSString*)input;
@end
