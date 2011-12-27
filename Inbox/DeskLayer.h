//
//  HelloWorldLayer.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/11/11.
//

#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"
#import "DeskProtocol.h"
#define NO_INTERNET_MESSAGE no connection
@class EmailNode;
@class EmailModel;

@interface DeskLayer : CCLayer{
	b2World* world;
	GLESDebugDraw *m_debugDraw;
    NSMutableArray *draggableNodes;
    EmailNode *draggedNode;
    id<DeskProtocol> delegate;
    CGPoint lastTouchPosition;
    NSTimeInterval lastTouchTime;
}
-(id) initWithDelegate:(id<DeskProtocol>)d;
-(void) putEmail:(EmailModel*)model;

-(void)didRotate;
-(void)willRotate;
-(void)willAppear;

@end

