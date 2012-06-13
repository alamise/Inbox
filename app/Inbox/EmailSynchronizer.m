#import "EmailSynchronizer.h"
#import "EmailAccountModel.h"
#import <CoreData/CoreData.h>
#import "CTCoreAccount.h"
#import "CTCoreMessage.h"
#import "AppDelegate.h"
#import "CTCoreFolder.h"
#import "MailCoreTypes.h"
#import "CTCoreAddress.h"
#import "FolderModel.h"
#import "EmailModel.h"
#import "DDLog.h"
#import "PersistMessagesSubSync.h"
#import "UpdateMessagesSubSync.h"
#import "FoldersSubSync.h"
#import "EmailSubSync.h"
#import "Deps.h"
#define ddLogLevel LOG_LEVEL_VERBOSE

@implementation EmailSynchronizer
@synthesize emailAccountModel;

- (id)initWithAccountId:(id)accountId {
    if ( self = [super init] ) {
        emailAccountModelId = [accountId retain];
        subSyncs = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [subSyncs release];
    [emailAccountModel release];
    [emailAccountModelId release];
    [super dealloc];
}


+ (NSString *)decodeImapString:(NSString *)input {
    NSMutableDictionary* translationTable = [[NSMutableDictionary alloc] init];
    [translationTable setObject:@"&" forKey:@"&-"];
    [translationTable setObject:@"é" forKey:@"&AOk-"];
    [translationTable setObject:@"â" forKey:@"&AOI-"];
    [translationTable setObject:@"à" forKey:@"&AOA-"];
    [translationTable setObject:@"è" forKey:@"&AOg"];
    [translationTable setObject:@"ç" forKey:@"&AOc"];
    [translationTable setObject:@"ù" forKey:@"&APk"];
    [translationTable setObject:@"ê" forKey:@"&AOo"];
    [translationTable setObject:@"î" forKey:@"&AO4"];
    [translationTable setObject:@"ó" forKey:@"&APM"];
    [translationTable setObject:@"ñ" forKey:@"&APE"];
    [translationTable setObject:@"á" forKey:@"&AOE"];
    [translationTable setObject:@"ô" forKey:@"&APQ"];                   
    [translationTable setObject:@"É" forKey:@"&AMk"];
    [translationTable setObject:@"ë" forKey:@"&AOs"];
    
    for ( NSString* key in [translationTable allKeys] ) {
        input = [input stringByReplacingOccurrencesOfString:key withString:[translationTable objectForKey:key]];
    }
    [translationTable release];
    return input;
}

- (void)stopAsap {
    [super stopAsap];
    for (EmailSubSync* subSync in subSyncs) {
        [subSync stopAsap];
    }
}

- (void)sync:(NSError **)error {
    DDLogVerbose(@"sync started");
    if ( !error ) {
        NSError* err = nil;
        error = &err;
    }
    *error = nil;
    emailAccountModel = (EmailAccountModel *)[[Deps sharedInstance].coreDataManager objectFromId:emailAccountModelId inContext:self.context error:nil];
    [emailAccountModel retain];
    DDLogVerbose(@"init with account ID %@",emailAccountModelId);
    if ( !emailAccountModel ) {
        *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:INVALID_ACCOUNT_ID_ERROR userInfo:nil];
        return;
    }
    if ( self.shouldStopAsap ) return ;/* STOP ASAP */
    
    DDLogVerbose(@"create sub syncs");
    FoldersSubSync *foldersSync = [[FoldersSubSync alloc] initWithContext:self.context account:emailAccountModel];
    PersistMessagesSubSync* persistSync = [[PersistMessagesSubSync alloc] initWithContext:self.context account:emailAccountModel];
    UpdateMessagesSubSync* updateSync = [[UpdateMessagesSubSync alloc] initWithContext:self.context account:emailAccountModel];
    [subSyncs addObject:foldersSync];
    [subSyncs addObject:persistSync];
    [subSyncs addObject:updateSync];
    
    DDLogVerbose(@"start folder subsync");
    [foldersSync syncWithError:error];
    if ( *error ) {
        DDLogError(@"sync ended with an error");
        return;
    }
    [foldersSync release];
    foldersSync = nil;
    if ( self.shouldStopAsap ) return ;/* STOP ASAP */
    
    DDLogVerbose(@"start persist subsync");
    [persistSync syncWithError:error];
    if ( *error ) {
        DDLogError(@"sync ended with an error");
        return;
    }
    if ( self.shouldStopAsap ) return ;/* STOP ASAP */
    DDLogVerbose(@"start update subsync");
    [updateSync syncWithError:error onStateChanged:^{
        [self onStateChanged];
    } periodicCall:^{
        [persistSync syncWithError:nil];
    }];
    if ( *error ){
        DDLogError(@"sync ended with an error");
        return;
    }
    if ( self.shouldStopAsap ) return ;/* STOP ASAP */
    
    DDLogVerbose(@"releasing subsyncs");
    [updateSync release];
    updateSync = nil;
    [persistSync release];
    persistSync = nil;
    
    [emailAccountModel release];
    emailAccountModel = nil;
    DDLogVerbose(@"sync successful");
    return;
}

@end
