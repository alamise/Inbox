//
//  DeskProtocol.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/30/11.
//

@class EmailModel,GmailModel;
@protocol DeskProtocol <NSObject>
    -(void)move:(EmailModel*)email to:(NSString*)folder;
    -(void)emailTouched:(EmailModel*)email;
    -(void)openSettings;
@end
