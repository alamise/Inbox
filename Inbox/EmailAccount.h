/*
 *
 * Copyright (c) 2012 Simon Watiau.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#import <Foundation/Foundation.h>

#import "CTCoreAccount.h"
#define SYNC_STARTED @"sync started"
#define SYNC_DONE @"sync done"
#define MODEL_UNACTIVE @"model unactive"
#define MODEL_ACTIVE @"model active"

#define MODEL_ERROR @"error"
#define INBOX_STATE_CHANGED @"new messages"
#define FOLDERS_READY @"folders ready"

@protocol DeskProtocol;
@class EmailModel;
@class EmailAccountModel;
@interface EmailAccount : NSObject{
    EmailAccountModel* accountModel;
    NSLock *syncLock;
    NSLock * writeChangesLock;
    BOOL stopActivitiesAsap;
    int activitiesCount;
}
@property(readonly) EmailAccountModel *accountModel;
-(id)initWithAccountModel:(EmailAccountModel*)accountModel;

-(void)sync;
-(BOOL)isActive;
-(void)stopActivitiesAsap;


-(NSManagedObjectID*)lastEmailFromFolder:(NSManagedObjectID*)folderId;
-(void)moveEmail:(NSManagedObjectID*)emailId toFolder:(NSManagedObjectID*)folderId;
-(int)emailsCountInFolder:(NSManagedObjectID*)folderId;
-(BOOL)fetchEmailBody:(NSManagedObjectID*)model;
-(NSArray*)folders;
-(BOOL)isSyncing;
@end
