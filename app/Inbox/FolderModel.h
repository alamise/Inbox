#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h> 

@class EmailAccountModel, EmailModel;

@interface FolderModel : NSManagedObject{
}
@property(nonatomic,retain) NSString* path;
@property(nonatomic,retain) EmailAccountModel* account;
@property(nonatomic,retain) NSSet* emails;
-(NSString*)hrTitle; // Human Readable title
+(NSString*)entityName;
@end


@interface FolderModel (CoreDataGeneratedAccessors)

- (void)addEmailsObject:(EmailModel *)value;
- (void)removeEmailsObject:(EmailModel *)value;
- (void)addEmails:(NSSet *)values;
- (void)removeEmails:(NSSet *)values;
@end