#import "FolderModel.h"
@interface FolderModel()
@end

@implementation FolderModel
@dynamic path;
@dynamic account;
@dynamic emails;

+ (void)initialize {
    
}

+ (NSString*)entityName {
    return @"Folder";
}

- (NSComparisonResult)compare:(FolderModel *)other {
    NSMutableArray* order = [[NSMutableArray alloc] init];
    [order addObject:NSLocalizedString(@"folderModel.path.archives", @"Localized Archives folder's path en: \"[Gmail]/All Mail\"")];
    [order addObject:NSLocalizedString(@"folderModel.path.starred", @"Localized Starred folder's path en:\"[Gmail]/Starred\"")];
    [order addObject:NSLocalizedString(@"folderModel.path.important", @"Localized Important folder's path en:\"[Gmail]/Important\"")];
    [order addObject:NSLocalizedString(@"folderModel.path.spam", @"Localized Spam folder's path en:\"[Gmail]/Spam\"")];
    [order addObject:NSLocalizedString(@"folderModel.path.trash", @"Localized Trash folder's path en:\"[Gmail]/Trash\"")];
    int myPos = [order indexOfObject:self.path];
    int itsPos = [order indexOfObject:other.path];
    [order release];
    if ((myPos!=NSNotFound)&&(itsPos!=NSNotFound)){
        if (myPos>itsPos){
            return NSOrderedDescending;
        }else if (myPos<itsPos){
            return NSOrderedAscending;
        }else{
            return NSOrderedSame;
        }
    }else if (myPos!=NSNotFound && itsPos==NSNotFound){
        return NSOrderedAscending;
    }else if (myPos==NSNotFound && itsPos!=NSNotFound){
        return NSOrderedDescending;
    }else {
        return NSOrderedAscending;
    }
}


-(NSString*)hrTitle{
    NSString* str = self.path;
    if ([self.path hasPrefix:@"[Gmail]/"]){
        str = [self.path substringFromIndex:8];
    }
    if ([str isEqualToString:@"All Mail"]){
        return @"Archive";
    }
    return str;
}
@end
