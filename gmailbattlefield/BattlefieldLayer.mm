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
#import "EmailNode.h"
#import "BFDelegateProtocol.h"
#import "BattlefieldModel.h"
#import "VisualEffectProtocol.h"
#define PTM_RATIO 32

enum {
	tagArchiveSprite = 1,
	tagInboxSprite = 2,
    tagPipeSprite = 3,
};

@interface BattlefieldLayer() 
@property(nonatomic,retain) EmailNode* draggedNode;
    -(void) putGround;
    -(void) putArchiveZone;
    -(void) putInboxZone;
    -(void) putPipeSprite;
    -(void) setOrUpdateScene;
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
	}
	return self;
}

-(void) putEmail:(EmailModel*)model{
    EmailNode* node = [[EmailNode alloc] initWithEmailModel:model];
    node.scale=0;
    [self addChild:node z:1];
	b2BodyDef bodyDef;
	bodyDef.type = b2_dynamicBody;
	bodyDef.position.Set([CCDirector sharedDirector].winSize.width/2/PTM_RATIO, [CCDirector sharedDirector].winSize.height/2/PTM_RATIO);
	bodyDef.userData = node;
    bodyDef.linearVelocity=b2Vec2(0,-2);
    bodyDef.linearDamping=3;
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
    if(!self.draggedNode.didMoved){
        [self.delegate emailTouched:self.draggedNode.emailModel];
        return;
    }
    UITouch* touch = [[touches allObjects] objectAtIndex:0]; 
    CGPoint oldLocation = [[CCDirector sharedDirector] convertToGL:[touch locationInView: [touch view]]];		
    CGPoint newLocation = [[CCDirector sharedDirector] convertToGL:[touch previousLocationInView: [touch view]]]
    ;
    
    
    for (b2Body* b = world->GetBodyList(); b; b = b->GetNext()){
		if (b->GetUserData() == self.draggedNode) {
            b->SetLinearVelocity(b2Vec2(oldLocation.x-newLocation.x, oldLocation.y-newLocation.y));
            b->SetAwake(true);
		}	
	}

    
    if (CGRectContainsPoint([self getChildByTag:tagArchiveSprite].boundingBox, newLocation)){
        [self.delegate email:self.draggedNode.emailModel sortedTo:folderArchive];
        [self.draggedNode hideAndRemove];
    }else if (CGRectContainsPoint([self getChildByTag:tagInboxSprite].boundingBox, newLocation)){
        [self.delegate email:self.draggedNode.emailModel sortedTo:folderInbox];
        [self.draggedNode hideAndRemove];
    }else{
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

-(void)setOrUpdateScene{
    [self putGround];
    [self putArchiveZone];
    [self putInboxZone];
    [self putPipeSprite];
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

-(void)putPipeSprite{
    CCSprite* sprite = (CCSprite*)[self getChildByTag:tagPipeSprite];
    if (sprite){
        sprite.visible = true;        
    }else{
        sprite = [CCSprite spriteWithFile:@"pipe.png"];    
        [self addChild:sprite z:0 tag:tagPipeSprite];
    }
    CGSize windowSize = [CCDirector sharedDirector].winSize;
    sprite.anchorPoint=CGPointMake(0, 0);
    sprite.position=CGPointMake(217, windowSize.height/2-40);
    

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

-(void)didAppear{
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

-(void)sortingDone{

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
