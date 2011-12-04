//
//  HelloWorldLayer.mm
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/11/11.
//

#import "BattlefieldLayer.h"
#import "GPLoadingBar.h"
#import "CTCoreAccount.h"
#import "CCNode.h"
#import "WordNode.h"
#import "BFDelegateProtocol.h"
#define PTM_RATIO 32

enum {
	tagBadZone = 1,
	tagGoodZone = 2,
};

@interface BattlefieldLayer() 
    -(void) setGround;
    -(void) setGoodZone;
    -(void) setBadZone;
    -(void) sortingDone;
    -(void) displayLoading;
    -(void) wakeup;
@end

@implementation BattlefieldLayer
@synthesize delegate;

+(CCScene *) scene{
	CCScene *scene = [CCScene node];
	BattlefieldLayer *layer = [BattlefieldLayer node];
	[scene addChild: layer];
	return scene;
}
-(id) init{
	if( (self=[super init])) {
        self.isTouchEnabled = YES;
		self.isAccelerometerEnabled = NO;
		world = new b2World(b2Vec2(0,0), true);
		world->SetContinuousPhysics(true);
		m_debugDraw = new GLESDebugDraw(PTM_RATIO);
		world->SetDebugDraw(m_debugDraw);
		
		uint32 flags = 0;
		flags += b2DebugDraw::e_shapeBit;
		m_debugDraw->SetFlags(flags);		
		
		draggableNodes = [[NSMutableArray alloc] init];
		[self schedule: @selector(tick:)];
        [self setGround];
        [self setGoodZone];
        [self setBadZone];
	}
	return self;
}

-(void)showLoadingView{
}

-(void)showDoneView{
}

-(void) putWord:(NSString*)word{
    WordNode* node = [[WordNode alloc] initWithWord:@"booom"];
    [self addChild:node z:1];
	b2BodyDef bodyDef;
	bodyDef.type = b2_dynamicBody;
	bodyDef.position.Set([CCDirector sharedDirector].winSize.width/2/PTM_RATIO, [CCDirector sharedDirector].winSize.height/2/PTM_RATIO);
	bodyDef.userData = node;
    bodyDef.linearVelocity=b2Vec2(30,30);
    bodyDef.linearDamping=1;
	b2Body *body = world->CreateBody(&bodyDef);

	b2CircleShape dynamicBox;
    dynamicBox.m_radius=1.5;
    
	b2FixtureDef fixtureDef;
	fixtureDef.shape = &dynamicBox;	
	fixtureDef.density = 0.3f;
	fixtureDef.friction = 0.3f;
    fixtureDef.restitution = 1;
	body->CreateFixture(&fixtureDef);
    
    [draggableNodes addObject:node];

}

#pragma mark - drag & drop

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch* touch = [[touches allObjects] objectAtIndex:0]; 
    CGPoint location = [[CCDirector sharedDirector] convertToGL:[touch locationInView: [touch view]]];		
    
    for (WordNode* node in draggableNodes){        
        CGRect rect = node.boundingBox;
        if (CGRectContainsPoint(rect, location)) {            
            draggedNode = [node retain];
            for (b2Body* b = world->GetBodyList(); b; b = b->GetNext()){
                if (b->GetUserData() ==draggedNode) {
                    b->SetLinearVelocity(b2Vec2(0,0));
                    b->SetAngularVelocity(0);
                    b->SetAwake(true);
                    break;
                }	
            }
        }
    }
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    if (!draggedNode){
        return;
    }
    
    UITouch* touch = [[touches allObjects] objectAtIndex:0]; 
    CGPoint touchLocation = [self convertTouchToNodeSpace:touch];
    CGPoint oldTouchLocation = [touch previousLocationInView:touch.view];
    oldTouchLocation = [[CCDirector sharedDirector] convertToGL:oldTouchLocation];
    oldTouchLocation = [self convertToNodeSpace:oldTouchLocation];
    
    CGPoint translation = ccpSub(touchLocation, oldTouchLocation);    
    CGPoint newPos = ccpAdd(draggedNode.position, translation);
    draggedNode.position = touchLocation;
    CGSize windowSize = [CCDirector sharedDirector].winSize;
    CGRect bounding = CGRectMake(0, 0, windowSize.width, windowSize.height);
    if (!CGRectContainsPoint(bounding, newPos)) return;
    for (b2Body* b = world->GetBodyList(); b; b = b->GetNext()){
		if (b->GetUserData() ==draggedNode) {
            b->SetTransform(b2Vec2(newPos.x/PTM_RATIO, newPos.y/PTM_RATIO), b->GetAngle());
            b->SetAwake(true);
		}	
	}
}

-(void)removeChildAndBody:(CCNode*)node{
    [self removeChild:node cleanup:YES];
    for (b2Body* b = world->GetBodyList(); b; b = b->GetNext()) {
        if (b->GetUserData()==node){
            world->DestroyBody(b);
            break;
        }
    }
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    if (!draggedNode){
        return;
    }
    UITouch* touch = [[touches allObjects] objectAtIndex:0]; 
    CGPoint location = [[CCDirector sharedDirector] convertToGL:[touch locationInView: [touch view]]];		
    BOOL sorted = false;
    if (CGRectContainsPoint([self getChildByTag:tagGoodZone].boundingBox, location)){
        sorted = true;
        [self.delegate sortedWord:draggedNode.word isGood:YES];
        [self removeChildAndBody:draggedNode];
    }else if (CGRectContainsPoint([self getChildByTag:tagBadZone].boundingBox, location)){
        sorted = false;
        [self.delegate sortedWord:draggedNode.word isGood:NO];
        [self removeChildAndBody:draggedNode];
    }else{
    }
    [draggedNode release];
    draggedNode=nil;
}



#pragma mark - draw battlefield

-(void) draw{
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_COLOR_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	world->DrawDebugData();
	glEnable(GL_TEXTURE_2D);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
}

-(void)setGround{
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
    groundBody->CreateFixture(&groundBox,0);
    // top
    groundBox.SetAsEdge(b2Vec2(0,windowSize.height/PTM_RATIO), b2Vec2(windowSize.width/PTM_RATIO,windowSize.height/PTM_RATIO));
    groundBody->CreateFixture(&groundBox,0);
    // left
    groundBox.SetAsEdge(b2Vec2(0,windowSize.height/PTM_RATIO), b2Vec2(0,0));
    groundBody->CreateFixture(&groundBox,0);
    // right
    groundBox.SetAsEdge(b2Vec2(windowSize.width/PTM_RATIO,windowSize.height/PTM_RATIO), b2Vec2(windowSize.width/PTM_RATIO,0));
    groundBody->CreateFixture(&groundBox,0);
}

-(void)setBadZone{
    CCSprite* sprite = (CCSprite*)[self getChildByTag:tagBadZone];
    if (sprite){
        sprite.visible = true;        
    }else{
        sprite = [CCSprite spriteWithFile:@"round.png"];    
        [self addChild:sprite z:0 tag:tagBadZone];
    }
    CGSize windowSize = [CCDirector sharedDirector].winSize;
    sprite.position=CGPointMake(sprite.contentSize.width/2, windowSize.height/2);
}

-(void)setGoodZone{
    CCSprite* sprite = (CCSprite*)[self getChildByTag:tagGoodZone];
    if (sprite){
        sprite.visible=true;        
    }else{
        sprite = [CCSprite spriteWithFile:@"round.png"];    
        [self addChild:sprite z:0 tag:tagGoodZone];
    }
    CGSize windowSize = [CCDirector sharedDirector].winSize;    
    sprite.position=CGPointMake(windowSize.width-sprite.contentSize.width/2, windowSize.height/2);
}


-(void)didAppear{
    [self setGround];
    [self setBadZone];
    [self setGoodZone];
}

-(void)willRotate{
    CCSprite* sprite = nil;
    sprite = (CCSprite*)[self getChildByTag:tagBadZone];
    if (sprite) sprite.visible=false;
    
    sprite = (CCSprite*)[self getChildByTag:tagGoodZone];
    if (sprite) sprite.visible=false;
}

-(void)didRotate{
    for (WordNode* node in draggableNodes){        
        CGRect rect = node.boundingBox;
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
    [self setGround];
    [self setBadZone];
    [self setGoodZone];
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

#pragma mark - life cycle

- (void) dealloc{
	delete world;
	world = NULL;	
	delete m_debugDraw;
    [draggableNodes release];
    [draggedNode release];
	[super dealloc];
}
@end
