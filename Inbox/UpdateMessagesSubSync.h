//
//  UpdateMessagesSynchronizer.h
//  Inbox
//
//  Created by Simon Watiau on 5/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EmailSubSync.h"
@class EmailAccountModel;
@class CTCoreAccount;

@interface UpdateMessagesSubSync : EmailSubSync{
    void(^onStateChanged)();
}

-(id)initWithContext:(NSManagedObjectContext*)c account:(EmailAccountModel*)a;
-(void)syncWithError:(NSError**)error onStateChanged:(void(^)()) osc;
@end
