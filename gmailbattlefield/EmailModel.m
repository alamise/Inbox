//
//  EmailModel.m
//  gmailbattlefield
//
//  Created by Simon Watiau on 12/11/11.
//

#import "EmailModel.h"

@implementation EmailModel
@synthesize senderEmail, senderName, summary,sentDate, uid, htmlBody, subject, path;

- (id)init{
    self = [super init];
    if (self) {
    }
    return self;
}

+(NSString*)entityName{
    return @"Email";
}
@end
