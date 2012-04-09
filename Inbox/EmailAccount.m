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

#import "EmailAccount.h"
#import "CTCoreAccount.h"
#import "CTCoreFolder.h"
#import "CTCoreMessage.h"
#import "CTCoreAddress.h"
#import "AppDelegate.h"
#import "EmailModel.h"
#import "MailCoreTypes.h"
#import "FolderModel.h"
#import "FlurryAnalytics.h"
#import "EmailAccountModel.h"

@interface EmailAccount()
-(BOOL)saveContext:(NSManagedObjectContext*)context;
-(BOOL)updateRemoteMessages:(CTCoreAccount*)account context:(NSManagedObjectContext*)context;
-(BOOL)updateLocalMessages:(CTCoreAccount*)account context:(NSManagedObjectContext*)context;
-(BOOL)updateLocalFolders:(CTCoreAccount*)account context:(NSManagedObjectContext*)context;
-(NSString*)decodeImapString:(NSString*)input;
-(void)executeCallbackCode:(dispatch_block_t) block;
@end

@implementation EmailAccount
@synthesize accountModel;

-(id)initWithAccountModel:(EmailAccountModel*)am {
    self = [self init];
    if (self) {
        accountModel = [am retain];
        syncLock = [[NSLock alloc] init];
        writeChangesLock = [[NSLock alloc] init];
        activitiesCount = 0;
    }
    return self;
}

-(void)dealloc{
    [syncLock release];
    [writeChangesLock release];
    [accountModel release];
    [super dealloc];
}


-(void)activityStarted{
    @synchronized(self){
        activitiesCount++;
        DDLogVerbose(@"GmailModel:activityEnded: Activity started (%d)",activitiesCount);
        if (activitiesCount==1){
            [self executeCallbackCode:^{
                [[NSNotificationCenter defaultCenter] postNotificationName:MODEL_ACTIVE object:nil];
            }];
        }
    }
}

-(void)executeCallbackCode:(dispatch_block_t) block{
    if (dispatch_get_current_queue() == dispatch_get_main_queue()){
        block();
    }else{
        dispatch_sync(dispatch_get_main_queue(), block);   
    }
}
                
                
-(void)activityEnded{
    @synchronized(self){
        activitiesCount--;
        DDLogVerbose(@"GmailModel:activityEnded: Activity ended (%d)",activitiesCount);
        if (activitiesCount==0){
            [self executeCallbackCode: ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:MODEL_UNACTIVE object:nil];
            }];
        }
    }    
}

-(BOOL)isActive{
    if([syncLock tryLock]){
        [syncLock unlock];
        if ([writeChangesLock tryLock]){
            [writeChangesLock unlock];
            return NO;
        }else{
            return YES;
        }
    }else{
        return YES;
    }
}

-(BOOL)isSyncing{
    if([syncLock tryLock]){
        [syncLock unlock];
        return NO;
    }else{
        return YES;
    }
}

-(void)sync{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
           });
}

-(BOOL)saveContext:(NSManagedObjectContext*)context{
    NSError* error = nil;
    [context save:&error];
    if (error){
        [self executeCallbackCode: ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:MODEL_ERROR object:error];
        }];
        return false;
    }else{
        return true;
    }
}


-(void)stopActivitiesAsap{
    stopActivitiesAsap = YES;
}


-(void)updateRemoteMessagesAsync{
    [self activityStarted];
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    if ([writeChangesLock tryLock]){
        [writeChangesLock unlock];
        CTCoreAccount* account = [[CTCoreAccount alloc] init];
        @try {
            //[account connectToServer:@"imap.gmail.com" port:993 connectionType:CONNECTION_TYPE_TLS authType:IMAP_AUTH_TYPE_PLAIN login:email password:password];
            [account connectToServer:accountModel.serverAddr port:accountModel.port connectionType:accountModel.conType authType:accountModel.authType login:accountModel.login password:accountModel.password];
        }
        @catch (NSException *exception) {
            [self executeCallbackCode:^{
                [[NSNotificationCenter defaultCenter] postNotificationName:MODEL_ERROR object:[NSError errorWithDomain:[exception description] code:0 userInfo:nil]];
            }];
            [account release];
            [self activityEnded];
            return;
        }
        NSManagedObjectContext* context = [[(AppDelegate*)[UIApplication sharedApplication].delegate newManagedObjectContext] retain];
        [self updateRemoteMessages:account context:context];
        [self saveContext:context];
        [context release];
        [account release];
    }
    [pool release];
    [self activityEnded];
}

#pragma mark - Model's methods


@end
