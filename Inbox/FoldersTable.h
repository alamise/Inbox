//
//  FoldersComponent.h
//  Inbox
//
//  Created by Simon Watiau on 4/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CCNode.h"
#import "SWTableView.h"

@interface FoldersTable : CCNode<SWTableViewDataSource>{
    SWTableView* table;
    NSArray* folders;
}
@property(nonatomic,retain) NSArray* folders;

@end
