//
//  EmailSynchronizer.h
//  Inbox
//
//  Created by Simon Watiau on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Synchronizer.h"
@class EmailAccountModel,CTCoreAccount,NSManagedObjectID;
@interface EmailSynchronizer : Synchronizer{
    EmailAccountModel* emailAccountModel;
    CTCoreAccount* coreAccount;
    NSManagedObjectID* emailAccountModelId;
}
-(id)initWithAccountId:(NSManagedObjectID*)accountId;
@property(nonatomic,readonly,retain) EmailAccountModel* emailAccountModel;
-(CTCoreAccount*)account;
-(NSSet*)disabledFolders;
+(NSString*)decodeImapString:(NSString*)input;
@end
