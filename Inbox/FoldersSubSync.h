//
//  FoldersSynchronizer.h
//  Inbox
//
//  Created by Simon Watiau on 5/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EmailSubSync.h"

@class EmailAccountModel;
@class CTCoreAccount;
@interface FoldersSubSync : EmailSubSync{

}

-(void)syncWithError:(NSError**)error;
@end
