#import "DrawingManager.h"
#import "cocos2d.h"
#import "InboxStack.h"
#import "Box2D.h"
#import "ProgressIndicator.h"
#import "ContextualRightSidePanel.h"
#import "DropZoneNode.h"

#define BACKGROUND_TAG 1
#define PROGRESS_INDICATOR_TAG 2
#define SETTINGS_BUTTON_TAG 3
#define CONTEXTUAL_SIDE_TAG 4
#define FAST_ARCHIVE_TAG 5
@implementation DrawingManager
@synthesize progressIndicator, inboxStack, rightSidePanel, fastArchiveZone;

-(id)initWithDelegate:(id<DrawingManagerDelegateProtocol>)d{
    if (self = [super init]){
        delegate = d;
        world = [delegate world];
        layer = [delegate layer];
        inboxStack = [[InboxStack alloc] initWithWorld:world];
        [self refresh];
    }
    return self;
}

-(void)refresh{
    [self drawGround];
    [self drawProgressIndicator];
    [self drawSettingsButton];
    [self setupContextualRightSideManager];
    [self drawFastArchiveZone];
}

- (void)drawGround {
    CCSprite* sprite = (CCSprite*)[layer getChildByTag:BACKGROUND_TAG];
    if (!sprite){
        sprite = [CCSprite spriteWithFile:@"woodBackground.png"];    
        [layer addChild:sprite z:0 tag:BACKGROUND_TAG];
    }
    sprite.anchorPoint=CGPointMake(0,0);
    sprite.position=CGPointMake(0,0);    
}

- (void)setupContextualRightSideManager {
    if (!rightSidePanel){
        rightSidePanel = [[ContextualRightSidePanel alloc] initWithLayer:layer];
    }
}

- (void)drawProgressIndicator {
    progressIndicator = (ProgressIndicator*)[layer getChildByTag:PROGRESS_INDICATOR_TAG];
    if (!progressIndicator){
        progressIndicator = [[ProgressIndicator alloc] init];
        [layer addChild:progressIndicator z:0 tag: PROGRESS_INDICATOR_TAG];
    }
    progressIndicator.position = CGPointMake(105, 100);
}

- (void)drawFastArchiveZone {
    CGSize windowSize = [CCDirector sharedDirector].winSize;
    fastArchiveZone = (DropZoneNode*)[layer getChildByTag:FAST_ARCHIVE_TAG];
    if (!fastArchiveZone){
        fastArchiveZone = [[DropZoneNode alloc] init];
        [layer addChild:fastArchiveZone z:0 tag: FAST_ARCHIVE_TAG];
    }
    fastArchiveZone.position = CGPointMake(20, 470);
    fastArchiveZone.title = NSLocalizedString(@"Archive", @"");
}

- (void)drawSettingsButton {
    CGSize windowSize = [CCDirector sharedDirector].winSize;
    CCMenu *starMenu = (CCMenu*)[layer getChildByTag:SETTINGS_BUTTON_TAG];
    if (!starMenu){
        CCMenuItem *starMenuItem = [CCMenuItemImage itemFromNormalImage:@"settingsUp.png" selectedImage:@"settingsDown.png" target:self selector:@selector(openSettings:)];
        starMenu = [CCMenu menuWithItems:starMenuItem, nil];
        [layer addChild:starMenu z:0 tag:SETTINGS_BUTTON_TAG];        
    }
    starMenu.position = CGPointMake(250,50);
}

- (void)openSettings:(id)sender {
    [delegate settingsButtonTapped];
}


-(void)scaleOut:(CCNode *)node {
    CCFiniteTimeAction* scale = [CCScaleTo actionWithDuration:0.5 scale:0];
    CCFiniteTimeAction* callback = [CCCallBlock actionWithBlock:^{
        [self removeChildAndBody:node];
    }];
    
    CCAction* sequence = [CCSequence actionOne:scale two:callback];
    [node runAction:sequence];
}

- (void)removeChildAndBody:(CCNode *)node {    
    for (b2Body* b = world->GetBodyList(); b; b = b->GetNext()) {
        if (b->GetUserData()==node){
            world->DestroyBody(b);
            break;
        }
    }
    [layer removeChild:node cleanup:YES];
}

@end
