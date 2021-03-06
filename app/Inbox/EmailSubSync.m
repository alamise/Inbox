#import "EmailSubSync.h"
#import <CoreData/CoreData.h>
#import "EmailAccountModel.h"
#import "CTCoreAccount.h"
#import "errorCodes.h"

@interface EmailSubSync ()
@property(nonatomic,retain,readwrite) NSManagedObjectContext* context;
@property(nonatomic,retain,readwrite) EmailAccountModel* accountModel;
@property(nonatomic,retain,readwrite) CTCoreAccount* coreAccount;

@end

@implementation EmailSubSync
@synthesize context, accountModel, coreAccount, shouldStopAsap;

-(id)initWithContext:(NSManagedObjectContext*)c account:(EmailAccountModel*)a{
    if (self = [self init]){
        self.context = c;
        NSAssert(a != nil, @"the account must not be nil");
        self.accountModel = a;
    }
    return self;
}

-(void)dealloc{
    self.accountModel = nil;
    self.context = nil;
    [super dealloc];
}

- (void)stopAsap {
    shouldStopAsap = true;
}

-(CTCoreAccount*)coreAccountWithError:(NSError**)error {
    if ( !error ) {
        NSError *err = nil;
        error = &err;
    }
    *error = nil;
    if (coreAccount == nil){
        coreAccount = [[CTCoreAccount alloc] init];
    }
    if (![coreAccount isConnected]){
        @try {
            [coreAccount connectToServer:self.accountModel.serverAddr port:[self.accountModel.port intValue] connectionType:[self.accountModel.conType intValue] authType:[self.accountModel.authType intValue] login:self.accountModel.login password:self.accountModel.password];            
        }
        @catch (NSException *exception) {
            *error = [NSError errorWithDomain:SYNC_ERROR_DOMAIN code:EMAIL_ERROR userInfo:[NSDictionary dictionaryWithObject:exception forKey:ROOT_EXCEPTION]];
            return nil;
        }
    }
    return coreAccount;
}

@end
