//
//  EmailModel.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 12/11/11.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BattlefieldModel.h"
@interface EmailModel : NSManagedObject{
    NSString* senderEmail;
    NSString* senderName;
    NSString* subject;
    NSDate* sentDate; /* GMT time */
    NSString* uid;
    NSString* htmlBody;
    NSString* path; /* path from the server*/ 
    NSString* newPath; /* next path of the email, will be update during the next round*/
    
}
@property(nonatomic,retain) NSString* senderEmail;
@property(nonatomic,retain) NSString* senderName;
@property(nonatomic,retain) NSString* subject;
@property(nonatomic,retain) NSString* summary;
@property(nonatomic,retain) NSDate* sentDate;
@property(nonatomic,retain) NSString* uid;
@property(nonatomic,retain) NSString* htmlBody;
@property(nonatomic,retain) NSString* path;
@property(nonatomic,retain) NSString* newPath;
+(NSString*)entityName;


@end
