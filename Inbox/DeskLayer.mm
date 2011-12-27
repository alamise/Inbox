//
//  HelloWorldLayer.mm
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/11/11.
//

#import "DeskLayer.h"
#import "CTCoreAccount.h"
#import "CCNode.h"
#import "EmailNode.h"
#import "DeskProtocol.h"
#import "GmailModel.h"
#import "VisualEffectProtocol.h"
#import "GLES-Render.h"
#define PTM_RATIO 32
#define TOUCHES_DELAY 0.1

enum {
	tagArchiveSprite = 1,
	tagInboxSprite = 2,
    tagBackgroundSprite = 3
};

@interface DeskLayer() 
@property(nonatomic,retain) EmailNode* draggedNode;
    -(void) putGround;
    -(void) putArchiveZone;
    -(void) putInboxZone;
    -(void) setOrUpdateScene;
@end

@implementation DeskLayer
@synthesize draggedNode;

-(id) initWithDelegate:(id<DeskProtocol>)d{
	if( (self=[super init])) {
        delegate = [d retain];
        self.isTouchEnabled = YES;
		self.isAccelerometerEnabled = NO;
		world = new b2World(b2Vec2(0,0), true);
		world->SetContinuousPhysics(true);
		m_debugDraw = new GLESDebugDraw(PTM_RATIO);
		world->SetDebugDraw(m_debugDraw);
        lastTouchTime=[NSDate timeIntervalSinceReferenceDate];
		uint32 flags = 0;
		flags += b2DebugDraw::e_shapeBit;
		m_debugDraw->SetFlags(flags);		
		
		draggableNodes = [[NSMutableArray alloc] init];
		[self schedule: @selector(tick:)];
	}
	return self;
}

- (void) dealloc{
	delete world;
	world = NULL;	
	delete m_debugDraw;
    [draggableNodes release];
    self.draggedNode = nil;
    [delegate release];
	[super dealloc];
}

-(void) putEmail:(EmailModel*)model{
    EmailNode* node = [[EmailNode alloc] initWithEmailModel:model];
    node.scale=0;
    [self addChild:node z:1];
	b2BodyDef bodyDef;
	bodyDef.type = b2_dynamicBody;
	bodyDef.position.Set(100/PTM_RATIO, [CCDirector sharedDirector].winSize.height/2/PTM_RATIO);
	bodyDef.userData = node;
    bodyDef.linearVelocity=b2Vec2(20,0);
    bodyDef.linearDamping=1.4;
	b2Body *body = world->CreateBody(&bodyDef);

	b2PolygonShape* dynamicBox = new b2PolygonShape();
    dynamicBox->SetAsBox(95/(float)PTM_RATIO,48/(float)PTM_RATIO);
    
	b2FixtureDef fixtureDef;
	fixtureDef.shape = dynamicBox;	
	fixtureDef.density = 5.f;
	fixtureDef.friction = 5.f;
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
    
    for (EmailNode* node in draggableNodes){        
        CGRect rect = node.boundingBox;
        if (CGRectContainsPoint(rect, location)) {            
            self.draggedNode = node;
            self.draggedNode.didMoved=false;
            for (b2Body* b = world->GetBodyList(); b; b = b->GetNext()){
                if (b->GetUserData() == draggedNode) {
                    b->SetLinearVelocity(b2Vec2(0,0));
                    b->SetAngularVelocity(0);
                    b->SetTransform(b->GetPosition(), 0);
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
    self.draggedNode.didMoved=true;
    UITouch* touch = [[touches allObjects] objectAtIndex:0]; 
    CGPoint touchLocation = [self convertTouchToNodeSpace:touch];
    CGPoint oldTouchLocation = [touch previousLocationInView:touch.view];
    oldTouchLocation = [[CCDirector sharedDirector] convertToGL:oldTouchLocation];
    oldTouchLocation = [self convertToNodeSpace:oldTouchLocation];
    
    CGPoint translation = ccpSub(touchLocation, oldTouchLocation);    
    CGPoint newPos = ccpAdd(self.draggedNode.position, translation);
    self.draggedNode.position = newPos;
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
        lastTouchPosition=[[CCDirector sharedDirector] convertToGL:[touch locationInView: [touch view]]];
    }
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    if (self.draggedNode==nil){
        return;
    }
    if(!self.draggedNode.didMoved){
        [delegate emailTouched:self.draggedNode.emailModel];
        return;
    }
    UITouch* touch = [[touches allObjects] objectAtIndex:0]; 
    CGPoint newLocation = [[CCDirector sharedDirector] convertToGL:[touch locationInView: [touch view]]]
    ;
    
    if (CGRectContainsPoint([self getChildByTag:tagArchiveSprite].boundingBox, newLocation)){
        [delegate move:self.draggedNode.emailModel to:@"[Gmail]/All Mail"];
        [self.draggedNode hideAndRemove];
    }else if (CGRectContainsPoint([self getChildByTag:tagInboxSprite].boundingBox, newLocation)){
        [delegate move:self.draggedNode.emailModel to:@"INBOX"];
        [self.draggedNode hideAndRemove];
    }else{
        // No effect if the mail is dropped in a zone.
        if (lastTouchTime<[NSDate timeIntervalSinceReferenceDate]+TOUCHES_DELAY){
            for (b2Body* b = world->GetBodyList(); b; b = b->GetNext()){
                if (b->GetUserData() == self.draggedNode) {
                    CGPoint point = ccpSub(newLocation,lastTouchPosition);
                    b->SetLinearVelocity(b2Vec2(point.x, point.y));
                    b->SetAwake(true);
                }	        
            }
        }
    }
}



#pragma mark - draw battlefield

-(void) draw{
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_COLOR_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	//world->DrawDebugData();
	glEnable(GL_TEXTURE_2D);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
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

-(void)setOrUpdateScene{
    [self putGround];
    [self putArchiveZone];
    [self putInboxZone];
}

-(void)putGround{
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
    
    CCSprite* sprite = (CCSprite*)[self getChildByTag:tagBackgroundSprite];
    if (sprite){
        sprite.visible = true;        
    }else{
        sprite = [CCSprite spriteWithFile:@"woodBackground.jpg"];    
        [self addChild:sprite z:0 tag:tagBackgroundSprite];
    }
    sprite.anchorPoint=CGPointMake(0, 0);
    sprite.position=CGPointMake(0,0);    
}

-(void)putArchiveZone{
    CCSprite* sprite = (CCSprite*)[self getChildByTag:tagArchiveSprite];
    if (sprite){
        sprite.visible = true;        
    }else{
        sprite = [CCSprite spriteWithFile:@"archiveZone.png"];    
        [self addChild:sprite z:0 tag:tagArchiveSprite];
    }
    CGSize windowSize = [CCDirector sharedDirector].winSize;
    sprite.position=CGPointMake(windowSize.width-sprite.contentSize.width/2, windowSize.height/2);
}


-(void)putInboxZone{
    CCSprite* sprite = (CCSprite*)[self getChildByTag:tagInboxSprite];
    if (sprite){
        sprite.visible=true;        
    }else{
        sprite = [CCSprite spriteWithFile:@"inboxZone.png"];    
        [self addChild:sprite z:0 tag:tagInboxSprite];
    }
    CGSize windowSize = [CCDirector sharedDirector].winSize;    
    sprite.position=CGPointMake(sprite.contentSize.width/2, windowSize.height/2);
}

-(void)willAppear{
    [self setOrUpdateScene];
}

-(void)willRotate{
    CCSprite* sprite = nil;
    sprite = (CCSprite*)[self getChildByTag:tagArchiveSprite];
    if (sprite) sprite.visible=false;
    
    sprite = (CCSprite*)[self getChildByTag:tagArchiveSprite];
    if (sprite) sprite.visible=false;
    CCLabelTTF* loadingLabel = (CCLabelTTF*)[self getChildByTag:tagArchiveSprite];
    if (loadingLabel){
        loadingLabel.visible = false;
    }
}

-(void)didRotate{
    for (EmailNode* node in draggableNodes){        
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
    [self setOrUpdateScene];
}

-(void) tick: (ccTime) dt{
	//http://gafferongames.com/game-physics/fix-your-timestep/
	int32 velocityIterations = 8;
	int32 positionIterations = 1;
	world->Step(dt, velocityIterations, positionIterations);
	for (b2Body* b = world->GetBodyList(); b; b = b->GetNext()){
		if (b->GetUserData() != NULL) {
			CCSprite *myActor = (CCSprite*)b->GetUserData();
            // TODO How can I hceck if a class implement a protocol
            if ([myActor respondsToSelector:@selector(isAppearing)]){
                id<VisualEffectProtocol> node = (id<VisualEffectProtocol>) myActor;
                if ([node shouldDisableCollisions]){
                    for (b2Fixture* f = b->GetFixtureList();f; f = f->GetNext()){
                        b->DestroyFixture(f);
                    }
                }
                [node setNextStep];
                if ([node shouldBeRemoved]){
                    [self removeChildAndBody:myActor];
                }
            }
            myActor.position = CGPointMake( b->GetPosition().x * PTM_RATIO, b->GetPosition().y * PTM_RATIO);
			myActor.rotation = -1 * CC_RADIANS_TO_DEGREES(b->GetAngle());
		}
	}
}

@end
