//
//  InteractionsManager.m
//  Inbox
//
//  Created by Simon Watiau on 4/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "InteractionsManager.h"
#import "cocos2d.h"
#import "Box2D.h"
#import "DeskLayer.h"
#import "config.h"
#import "CCNode.h"

#define TOUCHES_DELAY 0.1
#define LONG_PRESS_DELAY 0.5
@interface InteractionsManager()
@property(nonatomic,retain) id<ElementNodeProtocol> draggedNode;

@end

@implementation InteractionsManager
@synthesize draggedNode, world,visibleNodes;

-(id)initWithDelegate:(id<InteractionsManagerDelegateProtocol>)d{
    if (self = [super init]){
        delegate = d;
        layer = [delegate layer];
        visibleNodes = [[NSMutableArray alloc] init];
        world = new b2World(b2Vec2(0,0), true);
		world->SetContinuousPhysics(true);
        m_debugDraw = new GLESDebugDraw(PTM_RATIO);
        uint32 flags = 0;
		flags += b2DebugDraw::e_shapeBit;
		m_debugDraw->SetFlags(flags);	
		m_debugDraw = new GLESDebugDraw(PTM_RATIO);
		world->SetDebugDraw(m_debugDraw);
        lastTouchTime=[NSDate timeIntervalSinceReferenceDate];
        [self setWorldBounds];
    }
    return self;
}

-(void)dealloc{
    delete world;
	world = NULL;	
	delete m_debugDraw;
    [visibleNodes release];
    [super dealloc];
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
    lastTouchTime = [NSDate timeIntervalSinceReferenceDate];
    self.draggedNode = nil;
    CGPoint location = [[CCDirector sharedDirector] convertToGL:[touch locationInView: [[CCDirector sharedDirector] openGLView]]];
    for (id<ElementNodeProtocol> node in [visibleNodes reverseObjectEnumerator]){        
        CGRect rect = [node visualNode].boundingBox;
        if (CGRectContainsPoint(rect, location)) {
            self.draggedNode = node;
            [delegate interactionStarted];
            didDraggedNodeMoved = false;
            for (b2Body* b = world->GetBodyList(); b; b = b->GetNext()){
                if (b->GetUserData() == draggedNode) {
                    b->SetLinearVelocity(b2Vec2(0,0));
                    b->SetAngularVelocity(0);
                    b->SetTransform(b->GetPosition(), 0);
                    b->SetAwake(true);
                    return true;
                }
            }
        }
    }
    
    return YES;
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
    if (!self.draggedNode){
        return;
    }
    didDraggedNodeMoved = true;
    
    CGPoint touchLocation = [layer convertTouchToNodeSpace:touch];
    CGPoint oldTouchLocation = [touch previousLocationInView:touch.view];
    oldTouchLocation = [[CCDirector sharedDirector] convertToGL:oldTouchLocation];
    oldTouchLocation = [layer convertToNodeSpace:oldTouchLocation];
    
    CGPoint translation = ccpSub(touchLocation, oldTouchLocation);    
    CGPoint newPos = ccpAdd([self.draggedNode visualNode].position, translation);
    [self.draggedNode visualNode].position = newPos;
    CGSize windowSize = [CCDirector sharedDirector].winSize;
    CGRect bounding = CGRectMake(0, 0, windowSize.width, windowSize.height);
    if (!CGRectContainsPoint(bounding, newPos)) return;
    for (b2Body* b = world->GetBodyList(); b; b = b->GetNext()){
		if (b->GetUserData() == self.draggedNode) {
            b->SetTransform(b2Vec2(newPos.x/PTM_RATIO, newPos.y/PTM_RATIO), b->GetAngle());
            b->SetAwake(true);
		}	
	}
    
    if (lastTouchTime+TOUCHES_DELAY<[NSDate timeIntervalSinceReferenceDate]){
        lastTouchTime=[NSDate timeIntervalSinceReferenceDate];
        lastTouchPosition=[[CCDirector sharedDirector] convertToGL:[touch locationInView: [[CCDirector sharedDirector] openGLView]]];
    }
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
    CGPoint newLocation = [[CCDirector sharedDirector] convertToGL:[touch locationInView: [[CCDirector sharedDirector] openGLView]]];
    if (self.draggedNode == nil){
        if (lastTouchTime + LONG_PRESS_DELAY < [NSDate timeIntervalSinceReferenceDate]){
            [delegate longTouchOnPoint:newLocation];
            return;
        }
    }
    [delegate interactionEnded];
    
    if(!didDraggedNodeMoved){
        [delegate elementTouched:self.draggedNode];
        return;
    }else{
        BOOL shouldAddLinearVelocity = [delegate element:self.draggedNode droppedAt:newLocation];
        if (shouldAddLinearVelocity){
            for (b2Body* b = world->GetBodyList(); b; b = b->GetNext()){
                if (b->GetUserData() == [self.draggedNode visualNode]) {
                    CGPoint point = ccpSub(newLocation,lastTouchPosition);
                    b->SetLinearVelocity(b2Vec2(point.x, point.y));
                    b->SetAwake(true);
                }
            }
        }
    }
}

-(void)refresh{
    [self setWorldBounds];
    [self validateNodesCoords];
}

-(void)setWorldBounds{
    CGSize windowSize = [CCDirector sharedDirector].winSize;
    for (b2Body* b = world->GetBodyList(); b; b = b->GetNext()){
		if (b->GetUserData() == nil) {
            world->DestroyBody(b);
		}	
	}
    int margin = 10;
    b2BodyDef groundBodyDef;
    groundBodyDef.userData = nil;
    groundBodyDef.position.Set(0, 0);
    b2Body* groundBody = world->CreateBody(&groundBodyDef);
    b2PolygonShape groundBox;		
    // bottom
    
    
    groundBox.SetAsEdge(b2Vec2(-margin/PTM_RATIO,-margin/PTM_RATIO), b2Vec2(windowSize.width-margin/PTM_RATIO,2*margin/PTM_RATIO));
    b2FixtureDef def1;
	def1.shape = &groundBox;
	def1.density = 0;
    def1.filter.categoryBits=GROUND_CATEGORY;
    groundBody->CreateFixture(&def1);
    
    // top
    groundBox.SetAsEdge(b2Vec2(0,windowSize.height/PTM_RATIO), b2Vec2(windowSize.width/PTM_RATIO,windowSize.height/PTM_RATIO));
    b2FixtureDef def2;
	def2.shape = &groundBox;
	def2.density = 0;
    def2.filter.categoryBits=GROUND_CATEGORY;
    groundBody->CreateFixture(&def2);
    
    // left
    groundBox.SetAsEdge(b2Vec2(0,windowSize.height/PTM_RATIO), b2Vec2(0,0));
    b2FixtureDef def3;
	def3.shape = &groundBox;
	def3.density = 0;
    def3.filter.categoryBits=GROUND_CATEGORY;
    groundBody->CreateFixture(&def3);
    
    // right
    groundBox.SetAsEdge(b2Vec2(windowSize.width/PTM_RATIO,windowSize.height/PTM_RATIO), b2Vec2(windowSize.width/PTM_RATIO,0));
    b2FixtureDef def4;
	def4.shape = &groundBox;
	def4.density = 0;
    def4.filter.categoryBits=GROUND_CATEGORY;
    groundBody->CreateFixture(&def4);
}

-(void) validateNodesCoords{
    for (id<ElementNodeProtocol> node in visibleNodes){        
        CGRect rect = [node visualNode].boundingBox;
        CGSize windowSize = [CCDirector sharedDirector].winSize;
        if (!CGRectContainsRect(CGRectMake(0, 0, windowSize.width, windowSize.height),rect)){
            for (b2Body* b = world->GetBodyList(); b; b = b->GetNext()){
                if (b->GetUserData() ==node) {
                    b->SetTransform(b2Vec2(windowSize.width/PTM_RATIO/2, windowSize.height/PTM_RATIO/2), b->GetAngle());
                    b->SetAwake(true);
                }	
            }
        }
    }
}



-(void)registerNode:(id<ElementNodeProtocol>)node{
    [visibleNodes insertObject:node atIndex:0];
}

-(void)unregisterNode:(id<ElementNodeProtocol>)node{
    [visibleNodes removeObject:node];
}

-(void) tick: (ccTime) dt{
	//http://gafferongames.com/game-physics/fix-your-timestep/
	int32 velocityIterations = 8;
	int32 positionIterations = 1;
	world->Step(dt, velocityIterations, positionIterations);
	for (b2Body* b = world->GetBodyList(); b; b = b->GetNext()){
		if (b->GetUserData() != NULL) {
			CCSprite *myActor = (CCSprite*)b->GetUserData();
            myActor.position = CGPointMake( b->GetPosition().x * PTM_RATIO, b->GetPosition().y * PTM_RATIO);
			myActor.rotation = -1 * CC_RADIANS_TO_DEGREES(b->GetAngle());
		}
	}
}

-(void)drawDebugData{
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_COLOR_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	world->DrawDebugData();
	glEnable(GL_TEXTURE_2D);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
}

@end
