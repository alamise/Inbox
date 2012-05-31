#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class EmailAccountModel;
@class FolderModel;

@interface EmailModel : NSManagedObject{
}
@property(nonatomic,retain) NSString *uid;
@property(nonatomic,retain) NSString *subject;
@property(nonatomic,retain) NSString *serverPath;
@property(nonatomic,retain) NSDate *sentDate;
@property(nonatomic,retain) NSString *senderName;
@property(nonatomic,retain) NSString *senderEmail;
@property(nonatomic,retain) NSString *htmlBody;
@property(nonatomic,assign) NSNumber *read;
@property(nonatomic,assign) NSNumber *shouldPropagate;
@property(nonatomic,retain) FolderModel* folder;
+(NSString*)entityName;
@end
