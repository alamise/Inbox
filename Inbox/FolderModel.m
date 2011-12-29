//
//  FolderModel.m
//  Inbox
//
//

#import "FolderModel.h"


@implementation FolderModel
static NSMutableArray* ORDER;
@dynamic path;


+(void)initialize{
    ORDER = [[NSMutableArray alloc] init];
    [ORDER addObject:@"[Gmail]/All Mail"];
    [ORDER addObject:@"[Gmail]/Starred"];
    [ORDER addObject:@"[Gmail]/Important"];
    [ORDER addObject:@"[Gmail]/Spam"];
    [ORDER addObject:@"[Gmail]/Trash"];
}

+(NSString*)entityName{
    return @"Folder";
}

- (NSComparisonResult) compare:(FolderModel*) other{
    
    int myPos = [ORDER indexOfObject:self.path];
    int itsPos = [ORDER indexOfObject:other.path];
    
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
@end
