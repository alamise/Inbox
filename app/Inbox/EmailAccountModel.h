#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h> 

@interface EmailAccountModel : NSManagedObject{

}
@property(nonatomic,retain) NSNumber* authType;
@property(nonatomic,retain) NSNumber* conType;
@property(nonatomic,retain) NSString* login;
@property(nonatomic,retain) NSString* password;
@property(nonatomic,retain) NSNumber* port;
@property(nonatomic,retain) NSString* serverAddr;
@property(nonatomic,retain) NSMutableSet* folders;
+(NSString*)entityName;
@end
