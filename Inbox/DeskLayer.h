//
//  HelloWorldLayer.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/11/11.
//

#import "cocos2d.h"
#import "Box2D.h"
#import "DeskProtocol.h"
#import "DropZoneNode.h"
#import "SWTableView.h"
#import "GLES-Render.h"
@class EmailNode, EmailModel, SWTableView;

@interface DeskLayer : CCLayer<SWTableViewDataSource>{
	b2World* world;
	GLESDebugDraw *m_debugDraw;
    NSMutableArray *draggableNodes;
    EmailNode *draggedNode;
    id<DeskProtocol> delegate;
    CGPoint lastTouchPosition;
    NSTimeInterval lastTouchTime;
    SWTableView* foldersTable;
}
-(id) initWithDelegate:(id<DeskProtocol>)d;
-(void) putEmail:(EmailModel*)model;

-(void)didRotate;
-(void)willRotate;
-(void)willAppear;

@end

