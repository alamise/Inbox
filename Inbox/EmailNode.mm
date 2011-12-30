//
//  WordNode.m
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/30/11.
//
#import "EmailNode.h"
#import "EmailModel.h"
#import "cocos2d.h"
#import "Box2D.h"
#import "GameConfig.h"
#define ANIMATION_DELAY 0.3
@implementation EmailNode
@synthesize emailModel,didMoved,isAppearing,isDisappearing;

- (id)initWithEmailModel:(EmailModel*)model bodyDef:(b2BodyDef)bodyDef world:(b2World*)w{
    self = [super init];
    if (self) {
        world = w;
        self.emailModel = model;
        drawMe = true;

        // Body
        bodyDef.type = b2_dynamicBody;
        bodyDef.userData = self;
        body = world->CreateBody(&bodyDef);
        
        // Fixture
        b2PolygonShape* dynamicBox = new b2PolygonShape();
        dynamicBox->SetAsBox(95/(float)PTM_RATIO,48/(float)PTM_RATIO);
        b2FixtureDef fixtureDef;
        fixtureDef.shape = dynamicBox;	
        fixtureDef.density = 5.f;
        fixtureDef.friction = 5.f;
        fixtureDef.restitution = 1;
        body->CreateFixture(&fixtureDef);
        self.scale=0;
    }
    return self;    
}

-(void) draw {
    [super draw];
    if (drawMe){
        drawMe = false;
        // 217x135
        CCSprite* sprite = [CCSprite spriteWithFile:@"emailBackground.png"];
        sprite.position=CGPointMake(105,67);
        [self addChild:sprite];
        title = [[CCLabelTTF labelWithString:self.emailModel.senderName dimensions:CGSizeMake(180, 20) alignment:UITextAlignmentLeft lineBreakMode:UILineBreakModeTailTruncation fontName:@"Arial" fontSize:15] retain];
        title.color=ccc3(150, 150, 150);
        title.position=CGPointMake(105, 105);
        [self addChild:title];
        
        content = [[CCLabelTTF labelWithString:self.emailModel.subject dimensions:CGSizeMake(180, 65) alignment:UITextAlignmentLeft lineBreakMode:UILineBreakModeTailTruncation fontName:@"Arial" fontSize:13] retain];

        content.color=ccc3(0, 1, 0);
        content.position=CGPointMake(105, 56);
        
        [self addChild:content];
        [self setContentSize:CGSizeMake(217, 135)];
        [self setAnchorPoint:CGPointMake(0.5, 0.5)];
    }
}

-(void)onEnter{
    [super onEnter];
    [self runAction:[CCScaleTo actionWithDuration:ANIMATION_DELAY scale:1]];
}

-(void)scaleAndHide{
    world->DestroyBody(body);
    [self runAction:[CCScaleTo actionWithDuration:ANIMATION_DELAY scale:0]];
    [CCCallFunc actionWithTarget:self selector:@selector(remove)];
}


-(void)remove{
    [self removeFromParentAndCleanup:YES];    
}

-(void)dealloc{
    self.emailModel = nil;
    [title release];
    [content release];
    [super dealloc];
}

@end
