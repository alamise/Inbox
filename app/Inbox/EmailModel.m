#import "EmailModel.h"
#import "FolderModel.h"

@implementation EmailModel
@dynamic uid;
@dynamic subject;
@dynamic sentDate;
@dynamic senderName;
@dynamic senderEmail;
@dynamic htmlBody;
@dynamic serverPath;
@dynamic folder;
@dynamic read;
@dynamic shouldPropagate;

+(NSString*)entityName{
    return @"Email";
}

@end
