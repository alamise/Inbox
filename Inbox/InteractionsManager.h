//
//  InteractionsManager.h
//  Inbox
//
//  Created by Simon Watiau on 4/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ElementNodeProtocol.h"
#import "Box2D.h"
#import "GLES-Render.h"
#import "InteractionsManagerDelegateProtocol.h"
#import "cocos2d.h"

@class CCLayer;
@interface InteractionsManager : NSObject<CCTargetedTouchDelegate>{
    id<ElementNodeProtocol> draggedNode;
    NSMutableArray* visibleNodes;
    BOOL didDraggedNodeMoved;
	GLESDebugDraw *m_debugDraw;
    b2World* world;
    CCLayer* layer;
    
    CGPoint lastTouchPosition;
    NSTimeInterval lastTouchTime;
    id<InteractionsManagerDelegateProtocol> delegate;
}
@property(readonly) b2World* world;
@property(readonly) NSArray* visibleNodes;
-(id)initWithDelegate:(id<InteractionsManagerDelegateProtocol>)d;
-(void) tick: (ccTime) dt;
-(void) validateNodesCoords;

-(void)registerNode:(id<ElementNodeProtocol>)node;
-(void)unregisterNode:(id<ElementNodeProtocol>)node;
-(void)drawDebugData;

-(void)refresh;
@end
