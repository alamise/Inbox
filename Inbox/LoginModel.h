//
//  LoginModel.h
//  Inbox
//
//  Created by Simon Watiau on 5/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class EmailAccountModel;

@interface LoginModel : NSObject {
}

- (BOOL) validateEmail: (NSString *) candidate;
- (void) changeToGmailAccountWithLogin:(NSString*)login password:(NSString*)password error:(NSError**)error;
- (EmailAccountModel*) firstAccountWithError:(NSError**)error;
@end
