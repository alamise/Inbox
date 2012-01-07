/*
 *
 * Copyright (c) 2012 Simon Watiau.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#import "DeskLayer.h"
#import "CTCoreAccount.h"
#import "CCNode.h"
#import "EmailNode.h"
#import "DeskProtocol.h"
#import "GmailModel.h"
#import "GLES-Render.h"
#import "EmailModel.h"
#import "FolderModel.h"
#import "GameConfig.h"
#define TOUCHES_DELAY 0.1

enum {
	tagArchiveSprite = 1,
	tagInboxSprite = 2,
    tagBackgroundSprite = 3,
    tagScrollZone = 4,
    tagSettingsSprite = 5
};

@interface DeskLayer() 
@property(nonatomic,retain) EmailNode* draggedNode;
    -(void) putGround;
    -(void)putFoldersZones;
    -(void) putInboxZone;
    -(void)putSettings;
    -(void) setOrUpdateScene;
@end

@implementation DeskLayer
@synthesize draggedNode,folders;

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
		folders = nil;
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

-(void)registerWithTouchDispatcher {
    [[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:1 swallowsTouches:NO];
}

-(void)setFolders:(NSArray *)f{
    if (folders){
        [folders release];
        folders = nil;
    }
    folders = [f retain];
    [foldersTable reloadData];
    [foldersTable scrollToTop];
}
-(void) putEmail:(EmailModel*)model{
	b2BodyDef bodyDef;
	bodyDef.position.Set(100/PTM_RATIO, [CCDirector sharedDirector].winSize.height/2/PTM_RATIO);
    bodyDef.linearVelocity=b2Vec2(20,0);
    bodyDef.linearDamping=1.4;

    EmailNode* node = [[EmailNode alloc] initWithEmailModel:model bodyDef:bodyDef world:world];
    [self addChild:node z:1];

    [draggableNodes addObject:node];
    [node release];
}



#pragma mark - drag & drop

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
    self.draggedNode = nil;
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
    if (self.draggedNode){
        foldersTable.isTouchEnabled=FALSE;
    }
    return YES;
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
    if (!self.draggedNode){
        return;
    }
    self.draggedNode.didMoved=true;
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
    return;
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
    if (self.draggedNode==nil){
        return;
    }
    if(!self.draggedNode.didMoved){
        [delegate emailTouched:self.draggedNode.emailModel];
        return;
    }
    CGPoint newLocation = [[CCDirector sharedDirector] convertToGL:[touch locationInView: [touch view]]];
    
    SWTableView* table = (SWTableView*)[self getChildByTag:tagScrollZone];
    int cellIndex = [table cellIndexForTouch:touch];
    if (cellIndex!=-1){
        FolderModel* folder = [self.folders objectAtIndex:cellIndex];
        [delegate move:self.draggedNode.emailModel to:folder.path];
        [draggableNodes removeObject:self.draggedNode];
        [self.draggedNode scaleAndHide];
    }else if (CGRectContainsPoint([self getChildByTag:tagArchiveSprite].boundingBox, newLocation)){
        [delegate move:self.draggedNode.emailModel to:@"[Gmail]/All Mail"];
        [draggableNodes removeObject:self.draggedNode];
        [self.draggedNode scaleAndHide];
        
    }else if (CGRectContainsPoint([self getChildByTag:tagInboxSprite].boundingBox, newLocation)){
        [delegate move:self.draggedNode.emailModel to:@"INBOX"];
        [draggableNodes removeObject:self.draggedNode];
        [self.draggedNode scaleAndHide];
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
    foldersTable.isTouchEnabled=TRUE;
    return;
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
    [self putSettings];
    [self putFoldersZones];
    [self putInboxZone];
}

-(void)putSettings{
    CGSize windowSize = [CCDirector sharedDirector].winSize;
    CCMenu *starMenu = (CCMenu*)[self getChildByTag:tagSettingsSprite];
    if (!starMenu){
        CCMenuItem *starMenuItem = [CCMenuItemImage itemFromNormalImage:@"settingsUp.png" selectedImage:@"settingsDown.png" target:self selector:@selector(openSettings:)];
        starMenu = [CCMenu menuWithItems:starMenuItem, nil];
        [self addChild:starMenu z:0 tag:tagSettingsSprite];        
    }
    starMenu.position = CGPointMake(280,windowSize.height-60);
}


- (void)openSettings:(id)sender {
    [delegate openSettings];
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


-(void)putFoldersZones{
    CGSize windowSize = [CCDirector sharedDirector].winSize;
    foldersTable = (SWTableView*)[self getChildByTag:tagScrollZone];
    if (!foldersTable){
        foldersTable = [[SWTableView viewWithDataSource:self size:CGSizeMake(200, 748) container:nil] retain];
        [foldersTable setVerticalFillOrder:SWTableViewFillTopDown];
        [self addChild:foldersTable z:0 tag:tagScrollZone];
    }
    
    foldersTable.position=CGPointMake(windowSize.width-230,0);
    
    [foldersTable reloadData];
    [foldersTable scrollToTop];
    
}
-(CGSize)cellSizeForTable:(SWTableView *)table{
    return CGSizeMake(200, 280);
}

-(SWTableViewCell *)table:(SWTableView *)table cellAtIndex:(NSUInteger)idx{
    DropZoneNode* node =  [[[DropZoneNode alloc] init] autorelease];
    
    if (folders){
        FolderModel* folder = [self.folders objectAtIndex:idx];
        node.folderPath=folder.path;
    }else{
        switch (idx) {
            case 0:
                node.folderPath=@"Archive";
                break;
            case 1:
                node.folderPath=@"Starred";
                break;
            case 2:
                node.folderPath=@"Important";
                break;
            default:
                break;
        }

    }
    return node;
}

-(NSUInteger)numberOfCellsInTableView:(SWTableView *)table{
    if (self.folders){
        int count = [self.folders count];
        return count;
    }else{
        return 3;
    }
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

-(void)cleanDesk{
    for (EmailNode* node in draggableNodes){
        [node scaleAndHide];
    }
    [draggableNodes removeAllObjects];
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
            myActor.position = CGPointMake( b->GetPosition().x * PTM_RATIO, b->GetPosition().y * PTM_RATIO);
			myActor.rotation = -1 * CC_RADIANS_TO_DEGREES(b->GetAngle());
		}
	}
}

@end
