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
@class WordNode;
@interface BattlefieldLayer : CCLayer{
	b2World* world;
	GLESDebugDraw *m_debugDraw;
    NSMutableArray *draggableNodes;
    WordNode *draggedNode;
    id<BFDelegateProtocol> delegate;
}
@property(nonatomic,retain) id<BFDelegateProtocol> delegate;

-(void)showLoadingView;
-(void)showDoneView;
-(void) putWord:(NSString*)word;

-(void)didRotate;
-(void)willRotate;
-(void)willAppear;
-(void)didAppear;

@end

