//
//  HelloWorldLayer.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/11/11.
//
#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"

@interface BattlefieldLayer : CCLayer{
	b2World* world;
	GLESDebugDraw *m_debugDraw;
    NSMutableArray *_draggableElements;
    CCNode *_touchedNode;
}
+(CCScene *) scene;

@end
