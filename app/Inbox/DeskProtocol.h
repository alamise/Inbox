#import <CoreData/CoreData.h>

@class EmailModel,FolderModel;
@protocol DeskProtocol <NSObject>
- (EmailModel *)lastEmailFromFolder:(FolderModel *)folder;
- (FolderModel *)archiveFolderForEmail:(EmailModel *)email;
- (void)moveEmail:(EmailModel *)emailId toFolder:(FolderModel *)folderId;
- (void)emailTouched:(EmailModel *)email;
- (void)openSettings;
@end
