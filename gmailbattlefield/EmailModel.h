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
    NSString* summary;
    NSDate* sentDate; /* GMT time */
    NSString* uid;
    folderType sortedTo;
    
}
@property(nonatomic,retain) NSString* senderEmail;
@property(nonatomic,retain) NSString* senderName;
@property(nonatomic,retain) NSString* summary;
@property(nonatomic,retain) NSDate* sentDate;
@property(nonatomic,retain) NSString* uid;
@property(nonatomic,assign) folderType sortedTo;

+(NSString*)entityName;
@end
