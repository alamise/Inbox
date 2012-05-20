//
//  EmailSubSync.h
//  Inbox
//
//  Created by Simon Watiau on 5/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class NSManagedObjectContext, CTCoreAccount, EmailAccountModel;
@interface EmailSubSync : NSObject{
    NSManagedObjectContext* context;
    EmailAccountModel* accountModel;
    CTCoreAccount* coreAccount;
}
@property(nonatomic,retain,readonly) NSManagedObjectContext* context;
@property(nonatomic,retain,readonly) EmailAccountModel* accountModel;
@property(nonatomic,retain,readonly) CTCoreAccount* coreAccount;
-(id)initWithContext:(NSManagedObjectContext*)c account:(EmailAccountModel*)a;
@end
