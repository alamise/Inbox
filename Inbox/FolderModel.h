//
//  FolderModel.h
//  Inbox
//
//  Created by Simon Watiau on 12/28/11.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface FolderModel : NSManagedObject{
    NSString* path;
}
@property(nonatomic,retain) NSString* path;
+(NSString*)entityName;
@end
