//
//  UpdateMessagesSynchronizer.h
//  Inbox
//
//  Created by Simon Watiau on 5/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class EmailAccountModel;
@class CTCoreAccount;

@interface UpdateMessagesSynchronizer : NSObject{
    NSManagedObjectContext* context;
    EmailAccountModel* accountModel;
    CTCoreAccount* coreAccount;
    void(^onStateChanged)();
}

-(id)initWithContext:(NSManagedObjectContext*)c account:(EmailAccountModel*)a;
-(void)syncWithError:(NSError**)error onStateChanged:(void(^)()) osc;
@end
