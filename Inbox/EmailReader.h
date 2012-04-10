//
//  EmailReader.h
//  Inbox
//
//  Created by Simon Watiau on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reader.h"
#import "models.h"
#import "errorCodes.h"
@interface EmailReader : Reader
- (void) fetchEmailBody:(NSManagedObjectID*)emailId error:(NSError**)error;
- (NSManagedObjectID*) lastEmailFromFolder:(NSManagedObjectID *)folderId error:(NSError**)error;
- (void) moveEmail:(NSManagedObjectID*)emailId toFolder:(NSManagedObjectID *)folderId error:(NSError**)error;
- (NSArray*) foldersForAccount:(NSManagedObjectID*)accountId error:(NSError**)error;
- (int) emailsCountInFolder:(NSManagedObjectID*)folderId error:(NSError**)error;
@end
