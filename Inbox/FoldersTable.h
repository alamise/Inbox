//
//  FoldersComponent.h
//  Inbox
//
//  Created by Simon Watiau on 4/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CCNode.h"
#import "SWTableView.h"
#import "CCController.h"
@class FolderModel;
@interface FoldersTable : NSObject<SWTableViewDataSource,CCController>{
    SWTableView* table;
    NSArray* folders;
}
@property(nonatomic,retain) NSArray* folders;
-(FolderModel*) folderModelAtPoint:(CGPoint)point;
-(CGPoint) centerOfFolderAtPoint:(CGPoint)point;
-(CCNode*)view;

@end
