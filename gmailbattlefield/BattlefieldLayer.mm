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
    tagLoadingLabel = 3,
    tagWordPreloadedImage = 4
};

@interface BattlefieldLayer() 
    -(void) setGround;
    -(void) setGoodZone;
    -(void) setBadZone;
    -(void) sortingDone;
    -(void) displayLoading;
    -(void) wakeup;
@property(nonatomic,retain) WordNode* draggedNode;
@end

@implementation BattlefieldLayer
@synthesize delegate, draggedNode;

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
        // If the image is not 
        WordNode* sprite = [[WordNode alloc] initWithWord:@"loadind"];
        sprite.visible = false;
        [self addChild:sprite z:0 tag:tagWordPreloadedImage];
	}
	return self;
}

-(void)setLoadingViewVisible:(BOOL)visibility{
    isLoadingViewVisible = visibility;
    CCLabelTTF* loadingLabel = (CCLabelTTF*)[self getChildByTag:tagLoadingLabel];
    if (!loadingLabel && visibility){
        loadingLabel = [[CCLabelTTF alloc] initWithString:@"Loading" fontName:@"Marker Felt" fontSize:28];
        loadingLabel.tag = tagLoadingLabel;
        [self addChild:loadingLabel z:1];
    }
    if (visibility){
        CGSize windowSize = [CCDirector sharedDirector].winSize;    
        loadingLabel.position=CGPointMake(windowSize.width/2, windowSize.height-loadingLabel.boundingBox.size.height/2-5);
        loadingLabel.visible=true;
    }else{
        if (loadingLabel){
            loadingLabel.visible=false;
        }
    }
}

-(void)showDoneView{
}

-(void) putWord:(NSString*)word{
    WordNode* node = [[WordNode alloc] initWithWord:word];
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
    [node release];
}

#pragma mark - drag & drop

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    self.draggedNode = nil;
    UITouch* touch = [[touches allObjects] objectAtIndex:0]; 
    CGPoint location = [[CCDirector sharedDirector] convertToGL:[touch locationInView: [touch view]]];		
    
    for (WordNode* node in draggableNodes){        
        CGRect rect = node.boundingBox;
        if (CGRectContainsPoint(rect, location)) {            
            self.draggedNode = node;
            for (b2Body* b = world->GetBodyList(); b; b = b->GetNext()){
                if (b->GetUserData() == draggedNode) {
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
    if (!self.draggedNode){
        return;
    }
    
    UITouch* touch = [[touches allObjects] objectAtIndex:0]; 
    CGPoint touchLocation = [self convertTouchToNodeSpace:touch];
    CGPoint oldTouchLocation = [touch previousLocationInView:touch.view];
    oldTouchLocation = [[CCDirector sharedDirector] convertToGL:oldTouchLocation];
    oldTouchLocation = [self convertToNodeSpace:oldTouchLocation];
    
    CGPoint translation = ccpSub(touchLocation, oldTouchLocation);    
    CGPoint newPos = ccpAdd(self.draggedNode.position, translation);
    self.draggedNode.position = touchLocation;
    CGSize windowSize = [CCDirector sharedDirector].winSize;
    CGRect bounding = CGRectMake(0, 0, windowSize.width, windowSize.height);
    if (!CGRectContainsPoint(bounding, newPos)) return;
    for (b2Body* b = world->GetBodyList(); b; b = b->GetNext()){
		if (b->GetUserData() == self.draggedNode) {
            b->SetTransform(b2Vec2(newPos.x/PTM_RATIO, newPos.y/PTM_RATIO), b->GetAngle());
            b->SetAwake(true);
		}	
	}
}

-(void)removeChildAndBody:(CCNode*)node{

    for (b2Body* b = world->GetBodyList(); b; b = b->GetNext()) {
        if (b->GetUserData()==node){
            world->DestroyBody(b);
            break;
        }
    }
    [self removeChild:node cleanup:YES];
    [draggableNodes removeObject:node];
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    if (self.draggedNode==nil){
        return;
    }
    UITouch* touch = [[touches allObjects] objectAtIndex:0]; 
    CGPoint location = [[CCDirector sharedDirector] convertToGL:[touch locationInView: [touch view]]];		
    BOOL sorted = false;
    if (CGRectContainsPoint([self getChildByTag:tagGoodZone].boundingBox, location)){
        sorted = true;
        [self.delegate sortedWord:self.draggedNode.word isGood:YES];
        [self removeChildAndBody:self.draggedNode];
    }else if (CGRectContainsPoint([self getChildByTag:tagBadZone].boundingBox, location)){
        sorted = false;
        [self.delegate sortedWord:self.draggedNode.word isGood:NO];
        [self removeChildAndBody:self.draggedNode];
    }else{
    }
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
        sprite = [CCSprite spriteWithFile:@"badZone.png"];    
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
        sprite = [CCSprite spriteWithFile:@"goodZone.png"];    
        [self addChild:sprite z:0 tag:tagGoodZone];
    }
    CGSize windowSize = [CCDirector sharedDirector].winSize;    
    sprite.position=CGPointMake(windowSize.width-sprite.contentSize.width/2, windowSize.height/2);
}


-(void)didAppear{
    [self setGround];
    [self setBadZone];
    [self setGoodZone];
    if (isLoadingViewVisible){
        [self  setLoadingViewVisible:true];
    }

}

-(void)willRotate{
    CCSprite* sprite = nil;
    sprite = (CCSprite*)[self getChildByTag:tagBadZone];
    if (sprite) sprite.visible=false;
    
    sprite = (CCSprite*)[self getChildByTag:tagGoodZone];
    if (sprite) sprite.visible=false;
    CCLabelTTF* loadingLabel = (CCLabelTTF*)[self getChildByTag:tagLoadingLabel];
    if (loadingLabel){
        loadingLabel.visible = false;
    }
    
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
    if (isLoadingViewVisible){
        [self  setLoadingViewVisible:true];
    }
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
    self.draggedNode = nil;
	[super dealloc];
}
@end
