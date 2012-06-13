#import "LoginModel.h"
#import "Deps.h"
#import "CoreDataManager.h"
#import "SynchroManager.h"
#import "EmailAccountModel.h"
#import "errorCodes.h"
#import <CoreData/CoreData.h>
#import "MailCore.h"
#import "PrivateValues.h"
#import "DDLog.h"
#import "Logger.h"

@implementation LoginModel

- (void) changeToGmailAccountWithLogin:(NSString*)login password:(NSString*)password error:(NSError**)error {
    if ( !error ) {
        NSError* err;
        error = &err;
    }
    *error = nil;
    if (![self validateEmail:login]){
        *error = [NSError errorWithDomain:LOGIN_ERROR_DOMAIN code:EMAIL_INVALID_ERROR userInfo:nil];
        return;
    }
    [self changeAccountWithLogin:login
                    password:password
                    conType:CONNECTION_TYPE_TLS
                    authType:IMAP_AUTH_TYPE_PLAIN
                    port:993 server:@"imap.gmail.com"
                    error:error];
}

- (EmailAccountModel*) firstAccountWithError:(NSError**)error {
    if (!error){
        NSError* err = nil;
        error = &err;
    }
    *error = nil;
    NSManagedObjectContext* context = [[Deps sharedInstance].coreDataManager mainContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailAccountModel entityName] inManagedObjectContext:context];
    request.entity = entity;
    NSMutableArray *properties = [NSMutableArray array];
    [properties addObject:[entity.propertiesByName objectForKey:@"login"]];
    [properties addObject:[entity.propertiesByName objectForKey:@"password"]];
    [request setPropertiesToFetch:properties];
    NSArray* emailsModels = [context executeFetchRequest:request error:error];
    if (*error) {
        return nil;
    }
    if ( [emailsModels count] == 0 ) {
        return nil;
    }
    EmailAccountModel* model = [emailsModels lastObject];
    [context refreshObject:model mergeChanges:YES];
    return model;
}

- (void)abortSync:(void(^)())nextStep {
    SynchroManager* synchroManager = [Deps sharedInstance].synchroManager;
    [synchroManager abortSync:nextStep];
}

- (void) changeAccountWithLogin:(NSString*)login password:(NSString*)password conType:(int)conType authType:(int) authType port:(int)port server:(NSString*)server error:(NSError**)error {
    DDLogInfo(@"changing the account");
    if ( !error){
        NSError* err = nil;
        error = &err;
    }
    *error = nil;

    NSManagedObjectContext* context = [[Deps sharedInstance].coreDataManager mainContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailAccountModel entityName] inManagedObjectContext:context];
    request.entity = entity;
    NSArray* emailsModels = [context executeFetchRequest:request error:error];
    if (*error) {
        return;
    }
    
    for (EmailAccountModel* account in emailsModels){
        DDLogVerbose(@"Previous account deleted with ID %@",account.objectID);
        [context deleteObject:account];
    }
    EmailAccountModel* account = nil;
    @try {
        DDLogVerbose(@"creating a new account");
        account = [NSEntityDescription insertNewObjectForEntityForName:[EmailAccountModel entityName] inManagedObjectContext:context];
    }
    @catch ( NSException *exception ) {
        *error = [NSError errorWithDomain:LOGIN_ERROR_DOMAIN code:CHANGE_ACCOUNT_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
        return;
    }

    account.serverAddr = server;
    account.port = [NSNumber numberWithInt:port];
    account.conType = [NSNumber numberWithInt:conType];
    account.authType = [NSNumber numberWithInt:authType];
    account.login = login;
    account.password = password;
    [context save:error];
    if ( *error ) {
        DDLogError(@"changing the account ended with an error");
        *error = [NSError errorWithDomain:LOGIN_ERROR_DOMAIN code:CHANGE_ACCOUNT_ERROR userInfo:[NSDictionary dictionaryWithObject:*error forKey:ROOT_ERROR]];
    }
    DDLogVerbose(@"account updated");
}

- (BOOL) validateEmail: (NSString *) candidate {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@gmail\\.com";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex]; 
    return [emailTest evaluateWithObject:candidate];
}
@end
