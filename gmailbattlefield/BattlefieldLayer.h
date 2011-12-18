//
//  HelloWorldLayer.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/11/11.
//

#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"
#import "BFDelegateProtocol.h"
@class EmailNode;
@class EmailModel;

@interface BattlefieldLayer : CCLayer{
	b2World* world;
	GLESDebugDraw *m_debugDraw;
    NSMutableArray *draggableNodes;
    EmailNode *draggedNode;
    id<BFDelegateProtocol> delegate;
    CGPoint lastTouchPosition;
    NSTimeInterval lastTouchTime;
}
@property(nonatomic,retain) id<BFDelegateProtocol> delegate;
-(void) putEmail:(EmailModel*)model;

-(void)didRotate;
-(void)willRotate;
-(void)didAppear;

@end

