//
//  PersistMessagesSynchronizer.h
//  Inbox
//
//  Created by Simon Watiau on 5/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class EmailAccountModel;
@class CTCoreAccount;

@interface PersistMessagesSynchronizer : NSObject{
    NSManagedObjectContext* context;
    EmailAccountModel* accountModel;
    CTCoreAccount* coreAccount;
}
-(id)initWithContext:(NSManagedObjectContext*)c account:(EmailAccountModel*)a;
@end
