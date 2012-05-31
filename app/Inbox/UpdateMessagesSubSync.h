#import <Foundation/Foundation.h>
#import "EmailSubSync.h"
@class EmailAccountModel;
@class CTCoreAccount;

@interface UpdateMessagesSubSync : EmailSubSync{
    void(^onStateChanged)();
    void(^periodicCall)();
    NSMutableDictionary* foldersMessageCount;
}

-(void)syncWithError:(NSError**)error onStateChanged:(void(^)()) osc periodicCall:(void(^)()) periodic;
@end
