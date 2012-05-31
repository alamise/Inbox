#import <Foundation/Foundation.h>

@class EmailAccountModel;

@interface LoginModel : NSObject {
}

- (BOOL) validateEmail: (NSString *) candidate;
- (void) changeToGmailAccountWithLogin:(NSString*)login password:(NSString*)password error:(NSError**)error;
- (EmailAccountModel*) firstAccountWithError:(NSError**)error;
- (void)abortSync:(void(^)())nextStep;
@end
