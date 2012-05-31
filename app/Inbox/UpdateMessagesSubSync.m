#import "UpdateMessagesSubSync.h"
#import <CoreData/CoreData.h>
#import "EmailModel.h"
#import "FolderModel.h"
#import "errorCodes.h"
#import "CTCoreFolder.h"
#import "CTCoreAccount.h"
#import "CTCoreFolder.h"
#import "EmailAccountModel.h"
#import "EmailSynchronizer.h"
#import "CTCoreMessage.h"
#import "CTCoreAddress.h"
#import "DDLog.h"
#import "Logger.h"
#import "NSArray+CoreData.h"
#define DL_PAGE_SIZE 100

@interface UpdateMessagesSubSync ()
@end



@implementation UpdateMessagesSubSync

-(void)syncWithError:(NSError**)error onStateChanged:(void(^)()) osc periodicCall:(void(^)()) periodic{
    if ( self.shouldStopAsap ) return ;/* STOP ASAP */
    DDLogVerbose(@"Update local messages started");
    if (!error){
        NSError* err;
        error = &err;
    }
    *error = nil;
    foldersMessageCount = [[NSMutableDictionary alloc] init];
    onStateChanged = Block_copy(osc);
    periodicCall = Block_copy(periodic);
    [self updateLocalMessagesWithError:error];
    if ( *error ) {
        DDLogVerbose(@"Update local messages ended with an error");
    }
    [onStateChanged release];
    onStateChanged = nil;
    [periodicCall release];
    periodicCall = nil;
    DDLogVerbose(@"Update local messages successful");
}

-(void)dealloc{
    [onStateChanged release];
    [periodicCall release];
    [foldersMessageCount release];
    [super dealloc];
}

- (void)updateLocalMessagesWithError:(NSError **)error {
    if ( !error ) {
        NSError *err;
        error = &err;
    }
    *error = nil;
    if ( self.shouldStopAsap ) return ;/* STOP ASAP */
    /* get the folders model */
    NSFetchRequest *foldersRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *folderDescription = [NSEntityDescription entityForName:[FolderModel entityName] inManagedObjectContext:self.context];
    foldersRequest.entity = folderDescription;

    NSMutableArray* folders = [NSMutableArray arrayWithArray:[self.context executeFetchRequest:foldersRequest error:error]];
    folders = [NSMutableArray arrayWithArray:[folders ArrayOfManagedIds]];
    [foldersRequest release];
    if ( self.shouldStopAsap ) return ;/* STOP ASAP */
    if (*error){
        *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:*error forKey:ROOT_ERROR]];
        DDLogError(@"error when getting the local folders");
        return;
    }

    int currentFolderIndex = 0;
    int page = 0;
    int pageSize = 100;
    int updateRemoteCounter = 0;
    NSMutableDictionary* totalMessageCount = [NSMutableDictionary dictionary];
    
    while ([folders count] != 0) {
        if ( self.shouldStopAsap ) return ;/* STOP ASAP */
        if (updateRemoteCounter++ % 10 == 0){
            DDLogInfo(@"periodicCall block performed");
            periodicCall();
        }

        NSManagedObjectID *folderModelId = [folders objectAtIndex:currentFolderIndex];
        FolderModel* folderModel = (FolderModel *)[self.context objectRegisteredForID:folderModelId];
        if( !folderModel ){
            [folders removeObjectAtIndex:currentFolderIndex];
        }else{
            [self.context refreshObject:folderModel mergeChanges:NO];
            DDLogVerbose(@"processing folder %@",folderModel.path);
            CTCoreFolder* coreFolder = [self coreFolderForFolder:folderModel error:error];
            if ( self.shouldStopAsap ) return ;/* STOP ASAP */
            if ( *error ) {
                DDLogError(@"error when getting the CTCoreFolder");
                return;
            }
            [coreFolder connect];
            
            DDLogVerbose(@"building message buffer (page %d)",page);
            NSSet *messagesBuffer = [self nextCoreMessagesForFolder:folderModel coreFolder:coreFolder page:page error:error];
            if ( *error ) {
                DDLogError(@"error when getting the next CTCoreMessage for a the folder: %@",folderModel.path);
                return;
            }
            if ( self.shouldStopAsap ) return ;/* STOP ASAP */
            for ( CTCoreMessage* message in messagesBuffer ) {
                if ( self.shouldStopAsap ) return ;/* STOP ASAP */
                DDLogVerbose(@"processing a message");
                
                [self processCoreEmail:message folder:folderModel coreFolder:coreFolder error:error];
                if ( *error ) {
                    DDLogError(@"error When processing the current message");
                    return;
                }
            }
            DDLogVerbose(@"message buffer processed");
            [coreFolder disconnect];
            coreFolder = nil;
            if ([messagesBuffer count] == 0) {
                [folders removeObject:[folders objectAtIndex:currentFolderIndex]];
            }
            if ( self.shouldStopAsap ) return ;/* STOP ASAP */
            [self.context save:error];
            
            if (*error){
                *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:*error forKey:ROOT_ERROR]];
                DDLogError(@"error when saving the CoreData context");
                return;
            }
            DDLogInfo(@"onStateChanged block performed");
            onStateChanged();
            
            currentFolderIndex = currentFolderIndex+1;
            currentFolderIndex = currentFolderIndex % [folders count];
            
            if ( currentFolderIndex == 0 ) {
                DDLogVerbose(@"switching to page %d", page);
                page++;
            }    
        }
    }
}


-(void)processCoreEmail:(CTCoreMessage*)message folder:(FolderModel*)folder coreFolder:(CTCoreFolder*)coreFolder error:(NSError**)error {
    
    
    // Get the exisiting email or create a new one
    NSFetchRequest *emailRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailModel entityName] inManagedObjectContext:self.context];
    emailRequest.entity = entity;    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sentDate" ascending:YES];
    [emailRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [sortDescriptor release];
    
    EmailModel* emailModel = nil;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uid = %@ AND folder = %@", message.uid,folder];
    [emailRequest setPredicate:predicate];
    
    NSArray* matchingEmails = [self.context executeFetchRequest:emailRequest error:error];
    [emailRequest release];
    if ( self.shouldStopAsap ) return ;/* STOP ASAP */
    if (*error){
        *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:*error forKey:ROOT_ERROR]];
        return;   
    }
    
    if ([matchingEmails count]>0){
        emailModel = [matchingEmails objectAtIndex:0];
    }else{
        @try {
            emailModel = [NSEntityDescription insertNewObjectForEntityForName:[EmailModel entityName] inManagedObjectContext:self.context];
        }
        @catch (NSException *exception) {
            *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
            return;   
        }
    }
    
    // update the current email
    
    NSEnumerator* enumerator = [message.from objectEnumerator];
    CTCoreAddress* from;
    
    // The "sender" field is not valid
    if ( [message.from count] > 0 ) {
        from = [enumerator nextObject];
    }else{
        from = message.sender;
    }
    
    emailModel.senderName = from.name;
    emailModel.senderEmail = from.email;
    emailModel.subject = message.subject;
    emailModel.sentDate = message.sentDateGMT;
    emailModel.uid = message.uid;
    emailModel.read = [NSNumber numberWithBool:!message.isUnread];
    emailModel.serverPath = folder.path;
    if ( ![((NSNumber*)emailModel.shouldPropagate) boolValue] ) {
        emailModel.folder = folder;
    } else {
        DDLogVerbose(@"message's folder (server:%@ | local:%@) not changed : %@",emailModel.folder.path, emailModel.serverPath, emailModel.subject);
    }
}

- (CTCoreFolder *)coreFolderForFolder:(FolderModel *)folder error:(NSError **)error {
    if ( self.shouldStopAsap ) return nil;/* STOP ASAP */
    if (!error){
        NSError* err = nil;
        error = &err;        
    }
    *error = nil;
    
    CTCoreFolder* coreFolder;
    
    @try {
        CTCoreAccount* account = [self coreAccountWithError:error];
        if (*error){
            *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:*error forKey:ROOT_ERROR]];
            return nil;
        }   
        
        // Check this : http://github.com/mronge/MailCore/issues/2
        coreFolder = [account folderWithPath:folder.path]; 
        [coreFolder connect];
    }
    @catch (NSException *exception) {
        *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
        return nil;
    }
    return coreFolder;

}

-(NSSet*) nextCoreMessagesForFolder:(FolderModel*)folder coreFolder:(CTCoreFolder*)coreFolder page:(int)page error:(NSError **)error{
    if ( !error ){
        NSError *err;
        error = &err;
    }
    *error = nil;
    int coreFolderMessageCount = 0;
    if (![foldersMessageCount objectForKey:folder.objectID]){
        int count = [coreFolder totalMessageCount];
        [foldersMessageCount setObject:[NSNumber numberWithInt:count] forKey:folder.objectID];
    }
    coreFolderMessageCount = [[foldersMessageCount objectForKey:folder.objectID] intValue];

    NSSet *messages = [NSSet set];
    @try {
        int start = coreFolderMessageCount - (page+1) * DL_PAGE_SIZE; 
        if (start<0) start = 0;
        int end = coreFolderMessageCount - (page) * DL_PAGE_SIZE;
        if (end<0) end = 0;
        if ((start == 0) && (end == 0)) {
            return [NSSet set];
        }
        DDLogVerbose(@"message buffer build from index %d to index %d", start, end);
        messages = [coreFolder messageObjectsFromIndex:start toIndex:end];
    }
    @catch (NSException *exception) {
        *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_MESSAGES_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
        NSLog(@"%@",exception);
        DDLogVerbose(@"error when building the message buffer for page %d (total:%d)", page, coreFolderMessageCount);
        return [NSSet set];
    }

    return messages;
}

@end
