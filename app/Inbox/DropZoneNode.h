#import <Foundation/Foundation.h>
#import "SWTableViewCell.h"
@class CCLabelTTF,FolderModel;
@interface DropZoneNode : SWTableViewCell{
    CCLabelTTF* label;
    BOOL drawMe;
    NSString* title;
}
@property(nonatomic,retain) NSString* title;
+ (CGPoint) visualCenterFromRealCenter:(CGPoint)point;
+(CGSize) fullSize;
@end
