//
//  EmailReader.h
//  Inbox
//
//  Created by Simon Watiau on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reader.h"
#import "errorCodes.h"
@class  EmailModel,FolderModel,EmailAccountModel;
@interface EmailReader : Reader
+(EmailReader*)sharedInstance;

- (void) fetchEmailBody:(EmailModel*)emailId error:(NSError**)error;
-(EmailModel*)lastEmailFromInboxExcluded:(NSArray*)excludedMails error:(NSError**)error;
- (EmailModel*) lastEmailFromFolder:(FolderModel *)folderId exclude:(NSArray*)excludedMails error:(NSError**)error;
- (void) moveEmail:(EmailModel*)emailId toFolder:(FolderModel *)folderId error:(NSError**)error;
- (NSArray*) foldersForAccount:(EmailAccountModel*)accountId error:(NSError**)error;
-(int)emailsCountInInboxes:(NSError**)error;
- (int) emailsCountInFolder:(FolderModel*)folderId error:(NSError**)error;
@end
