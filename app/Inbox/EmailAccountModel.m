#import "EmailAccountModel.h"
#import <CoreData/CoreData.h>

@implementation EmailAccountModel
@dynamic login;
@dynamic password;
@dynamic serverAddr;
@dynamic conType;
@dynamic authType;
@dynamic port;
@dynamic folders;


+(NSString*)entityName{
    return @"EmailAccount";
}

@end
