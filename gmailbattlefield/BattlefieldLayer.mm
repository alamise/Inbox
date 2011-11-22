//
//  HelloWorldLayer.mm
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/11/11.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//

#import "BattlefieldLayer.h"
#import "GPLoadingBar.h"
#import "CTCoreAccount.h"
#import "CCNode.h"
#define PTM_RATIO 32
enum {
	tagBadZone = 1,
	tagGoodZone = 2,
};

@implementation BattlefieldLayer

+(CCScene *) scene{
	CCScene *scene = [CCScene node];
	BattlefieldLayer *layer = [BattlefieldLayer node];
	[scene addChild: layer];
	return scene;
}

-(void)redraw{
    for (CCLabelTTF* node in _draggableElements){        
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

    [self drawGround];
    [self drawBadDropZone];
    [self drawGoodDropZone];
}

-(id) init{
	if( (self=[super init])) {

        self.isTouchEnabled = YES;
		self.isAccelerometerEnabled = NO;
		CGSize screenSize = [CCDirector sharedDirector].winSize;
		world = new b2World(b2Vec2(0,0), true);
		world->SetContinuousPhysics(true);
		m_debugDraw = new GLESDebugDraw(PTM_RATIO);
		world->SetDebugDraw(m_debugDraw);
		
		uint32 flags = 0;
		flags += b2DebugDraw::e_shapeBit;
        //		flags += b2DebugDraw::e_jointBit;
        //		flags += b2DebugDraw::e_aabbBit;
        //		flags += b2DebugDraw::e_pairBit;
        //		flags += b2DebugDraw::e_centerOfMassBit;
		m_debugDraw->SetFlags(flags);		
		
		_draggableElements = [[NSMutableArray alloc] init];

        [self addWord:@"merde"];
		[self schedule: @selector(tick:)];
        [self drawBackground];
        [self drawBadDropZone];
        [self drawGoodDropZone];
        //[self drawLoadingBar];
	}
	return self;
}

-(void) draw{
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_COLOR_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	
	world->DrawDebugData();
	
	// restore default GL states
	glEnable(GL_TEXTURE_2D);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
}

-(void)drawGround{
    CGSize windowSize = [CCDirector sharedDirector].winSize;
    for (b2Body* b = world->GetBodyList(); b; b = b->GetNext()){
		if (b->GetUserData() == nil) {
            world->DestroyBody(b);
		}	
	}

    b2BodyDef groundBodyDef;
    groundBodyDef.userData = nil;
    groundBodyDef.position.Set(0, 0);
    b2Body* groundBody = world->CreateBody(&groundBodyDef);
    b2PolygonShape groundBox;		
    // bottom
    groundBox.SetAsEdge(b2Vec2(0,0), b2Vec2(windowSize.width/PTM_RATIO,0));
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

-(void)drawBackground{
    //CCSprite* sprite = [CCSprite spriteWithFile:@"background.png"];
    //[self addChild:sprite z:0];
}
-(void)drawLoadingBar{
    GPLoadingBar *loadingBar = [GPLoadingBar loadingBarWithBar:@"bar.png" inset:@"inset.png" mask:@"mask.png"];
    loadingBar.position=CGPointMake(0, 0);
    [self addChild:loadingBar];
    loadingBar.loadingProgress = 50;
}

-(void)drawBadDropZone{
    if ([self getChildByTag:tagBadZone]){
        [self removeChildByTag:tagBadZone cleanup:YES];
    }
    CGSize windowSize = [CCDirector sharedDirector].winSize;
    
    CCSprite* sprite = [CCSprite spriteWithFile:@"round.png"];
    sprite.position=CGPointMake(sprite.contentSize.width/2, windowSize.height/2);
    [self addChild:sprite z:0 tag:tagBadZone];
}

-(void)drawGoodDropZone{
    if ([self getChildByTag:tagGoodZone]){
        [self removeChildByTag:tagGoodZone cleanup:YES];
    }
    CGSize windowSize = [CCDirector sharedDirector].winSize;
    
    CCSprite* sprite = [CCSprite spriteWithFile:@"round.png"];
    sprite.position=CGPointMake(windowSize.width-sprite.contentSize.width/2, windowSize.height/2);
    [self addChild:sprite z:0 tag:tagGoodZone];
}

-(void) addWord:(NSString*)word{
    
    CGSize maxSize = [word sizeWithFont:[UIFont fontWithName:@"Marker Felt" size:24]];
    CCNode* node = [[CCNode alloc] init];
    CCLabelTTF *label = [CCLabelTTF labelWithString:word fontName:@"Marker Felt" fontSize:24];
    label.position=CGPointMake(100, 100);
    [node addChild:label];
    [node setContentSizeInPixels:CGSizeMake(100, 100)];
    [self addChild:node z:1];    
	b2BodyDef bodyDef;

	bodyDef.type = b2_dynamicBody;

	bodyDef.position.Set([CCDirector sharedDirector].winSize.width/2/PTM_RATIO, [CCDirector sharedDirector].winSize.height/2/PTM_RATIO);
	bodyDef.userData = node;
    bodyDef.linearVelocity=b2Vec2(1,1);
    bodyDef.linearDamping=1;
	b2Body *body = world->CreateBody(&bodyDef);
	
	b2PolygonShape dynamicBox;
	dynamicBox.SetAsBox(maxSize.width/PTM_RATIO, maxSize.height/PTM_RATIO);//These are mid points for our 1m 
	b2FixtureDef fixtureDef;
	fixtureDef.shape = &dynamicBox;	
	fixtureDef.density = 0.3f;
	fixtureDef.friction = 0.3f;
	body->CreateFixture(&fixtureDef);
    
    [_draggableElements addObject:node];
}



-(void) tick: (ccTime) dt
{
	//It is recommended that a fixed time step is used with Box2D for stability
	//of the simulation, however, we are using a variable time step here.
	//You need to make an informed choice, the following URL is useful
	//http://gafferongames.com/game-physics/fix-your-timestep/
	
	int32 velocityIterations = 8;
	int32 positionIterations = 1;
	
	// Instruct the world to perform a single step of simulation. It is
	// generally best to keep the time step and iterations fixed.
	world->Step(dt, velocityIterations, positionIterations);
    
	
	//Iterate over the bodies in the physics world
	for (b2Body* b = world->GetBodyList(); b; b = b->GetNext())
	{
		if (b->GetUserData() != NULL) {
			//Synchronize the AtlasSprites position and rotation with the corresponding body
			CCSprite *myActor = (CCSprite*)b->GetUserData();
			myActor.position = CGPointMake( b->GetPosition().x * PTM_RATIO, b->GetPosition().y * PTM_RATIO);
			myActor.rotation = -1 * CC_RADIANS_TO_DEGREES(b->GetAngle());
		}	
	}
}



-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch* touch = [[touches allObjects] objectAtIndex:0]; 
    CGPoint location = [[CCDirector sharedDirector] convertToGL:[touch locationInView: [touch view]]];		

    for (CCNode* node in _draggableElements){        
        CGRect rect = node.boundingBox;
        if (CGRectContainsPoint(rect, location)) {            
            _touchedNode = [node retain];
            break;
        }
    }
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    if (!_touchedNode){
        return;
    }
    UITouch* touch = [[touches allObjects] objectAtIndex:0]; 
    
    CGPoint touchLocation = [self convertTouchToNodeSpace:touch];
    
    CGPoint oldTouchLocation = [touch previousLocationInView:touch.view];
    oldTouchLocation = [[CCDirector sharedDirector] convertToGL:oldTouchLocation];
    oldTouchLocation = [self convertToNodeSpace:oldTouchLocation];
    
    CGPoint translation = ccpSub(touchLocation, oldTouchLocation);    

    CGPoint newPos = ccpAdd(_touchedNode.position, translation);
    _touchedNode.position = newPos;
    for (b2Body* b = world->GetBodyList(); b; b = b->GetNext()){
		if (b->GetUserData() ==_touchedNode) {
            b->SetTransform(b2Vec2(newPos.x/PTM_RATIO, newPos.y/PTM_RATIO), b->GetAngle());
            b->SetAwake(true);
		}	
	}
    _touchedNode.position = newPos;
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    if (!_touchedNode){
        return;
    }
    UITouch* touch = [[touches allObjects] objectAtIndex:0]; 
    CGPoint location = [[CCDirector sharedDirector] convertToGL:[touch locationInView: [touch view]]];		
    if (CGRectContainsPoint([self getChildByTag:tagGoodZone].boundingBox, location)){
        NSLog(@"good zone");
        [self removeChildAndBody:_touchedNode];
        [self addWord:@"boum"];
    }else if (CGRectContainsPoint([self getChildByTag:tagBadZone].boundingBox, location)){
        NSLog(@"bad zone");
        [self removeChildAndBody:_touchedNode];
        [self addWord:@"boum"];
    }else{
        NSLog(@"nothing");
    }

    [_touchedNode release];
    _touchedNode=nil;
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

- (void)accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration
{	
	static float prevX=0, prevY=0;
	
	//#define kFilterFactor 0.05f
#define kFilterFactor 1.0f	// don't use filter. the code is here just as an example
	
	float accelX = (float) acceleration.x * kFilterFactor + (1- kFilterFactor)*prevX;
	float accelY = (float) acceleration.y * kFilterFactor + (1- kFilterFactor)*prevY;
	
	prevX = accelX;
	prevY = accelY;
	
	// accelerometer values are in "Portrait" mode. Change them to Landscape left
	// multiply the gravity by 10
	b2Vec2 gravity( -accelY * 10, accelX * 10);
	
	world->SetGravity( gravity );
}

- (void) dealloc{
	delete world;
	world = NULL;	
	delete m_debugDraw;
    [_draggableElements release];
	[super dealloc];
}
@end
