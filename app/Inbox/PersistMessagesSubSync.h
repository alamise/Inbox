#import <Foundation/Foundation.h>
#import "EmailSubSync.h"

@class EmailAccountModel;
@class CTCoreAccount;

@interface PersistMessagesSubSync : EmailSubSync{
}

-(void)syncWithError:(NSError**)error;
@end
