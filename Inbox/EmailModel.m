//
//  EmailModel.m
//  gmailbattlefield
//
//  Created by Simon Watiau on 12/11/11.
//

#import "EmailModel.h"

@implementation EmailModel
@dynamic uid;
@dynamic subject;
@dynamic sentDate;
@dynamic senderName;
@dynamic senderEmail;
@dynamic path;
@dynamic newPath;
@dynamic htmlBody;


+(NSString*)entityName{
    return @"Email";
}
- (void)didTurnIntoFault{
    [super didTurnIntoFault];
}
@end
