#import <Foundation/Foundation.h>
#import "EmailSubSync.h"

@class EmailAccountModel;
@class CTCoreAccount;
@interface FoldersSubSync : EmailSubSync{
}

-(void)syncWithError:(NSError**)error;
@end
