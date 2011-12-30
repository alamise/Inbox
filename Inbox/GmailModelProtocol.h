//
//  BFModelProtocol.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 12/4/11.
//

#import <Foundation/Foundation.h>

@protocol GmailModelProtocol <NSObject>
@required
    - (void)onError:(NSString*)errorMessage;
    -(void)syncDone;
@end
