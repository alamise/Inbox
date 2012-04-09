//
//  EmailSynchronizer.h
//  Inbox
//
//  Created by Simon Watiau on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Synchronizer.h"

@class EmailAccountModel;
@interface EmailSynchronizer : Synchronizer
-(BOOL)syncAccount:(EmailAccountModel*)accountModel;
@end
