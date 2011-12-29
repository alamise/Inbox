//
//  DropZoneNode.h
//  Inbox
//
//  Created by Simon Watiau on 12/27/11.
//

#import <Foundation/Foundation.h>
#import "SWTableViewCell.h"
@class CCLabelTTF;
@interface DropZoneNode : SWTableViewCell{
    CCLabelTTF* label;
    BOOL drawMe;
    NSString* folderPath;
}
@property(nonatomic,retain)NSString* folderPath;
@end
