//
//  FoldersComponent.m
//  Inbox
//
//  Created by Simon Watiau on 4/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FoldersTable.h"
#import "DropZoneNode.h"

@implementation FoldersTable
@synthesize folders;
-(id)init{
    if (self = [super init]){
        self.contentSize = CGSizeMake(240, 748);
        table = [[SWTableView viewWithDataSource:self size:CGSizeMake(240, 748) container:nil] retain];
        [table setVerticalFillOrder:SWTableViewFillTopDown];
        [self addChild:table z:0];
        table.position=CGPointMake(0,0);
        self.position = CGPointMake(0, 0);
    }
    return self;
}

-(void)dealloc{
    [table release];
    self.folders = nil;
    [super dealloc];
}

-(void)setFolders:(NSArray *)f{
    [folders autorelease];
    folders = [f retain];
    [table reloadData];
}

-(CGSize)cellSizeForTable:(SWTableView *)table{
    return CGSizeMake(240, 280);
}

-(SWTableViewCell *)table:(SWTableView *)table cellAtIndex:(NSUInteger)idx{
    DropZoneNode* node =  [[[DropZoneNode alloc] init] autorelease];
    
    if (folders){
        FolderModel* folder = [self.folders objectAtIndex:idx];
        node.folder = folder;
    }else{
        node.folder =  nil; 
    }
    return node;
}

-(NSUInteger)numberOfCellsInTableView:(SWTableView *)table{
    if (self.folders){
        int count = [self.folders count];
        return count;
    }
    return 0;
}


@end
