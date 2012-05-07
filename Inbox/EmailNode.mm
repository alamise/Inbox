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
#import "EmailNode.h"
#import "EmailModel.h"
#import "cocos2d.h"
#import "Box2D.h"
#import "config.h"
#import "AppDelegate.h"
#import "DeskLayer.h"
#define ANIMATION_DELAY 0.3

@interface EmailNode ()
-(void) draw:(NSString*)subject senderName:(NSString*)senderName;
@property(nonatomic,retain) NSManagedObjectID* emailId;
@end

@implementation EmailNode

@synthesize didMoved,isAppearing,isDisappearing,emailId;

- (id)initWithEmailModel:(EmailModel*)model bodyDef:(b2BodyDef)bodyDef world:(b2World*)w{
    self = [super init];
    if (self) {
        world = w;
        [self draw:model.subject senderName:model.senderName];
        self.emailId = model.objectID;
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
        fixtureDef.filter.categoryBits = EMAIL_CATEGORY;
        fixtureDef.filter.maskBits = EMAIL_MASK;
        body->CreateFixture(&fixtureDef);
        //self.scale=0;
        free(dynamicBox);
    }
    return self;    
}


-(void) draw:(NSString*)subject senderName:(NSString*)senderName {
    // 217x135
    CCSprite* sprite = [CCSprite spriteWithFile:@"emailBackground.png"];
    sprite.position=CGPointMake(105,67);
    [self addChild:sprite];
    title = [[CCLabelTTF labelWithString:senderName dimensions:CGSizeMake(180, 20) alignment:UITextAlignmentLeft lineBreakMode:UILineBreakModeTailTruncation fontName:@"Arial" fontSize:15] retain];
    title.color=ccc3(150, 150, 150);
    title.position=CGPointMake(105, 105);
    [self addChild:title];
    
    content = [[CCLabelTTF labelWithString:subject dimensions:CGSizeMake(180, 65) alignment:UITextAlignmentLeft lineBreakMode:UILineBreakModeTailTruncation fontName:@"Arial" fontSize:13] retain];
    
    content.color=ccc3(0, 1, 0);
    content.position=CGPointMake(105, 56);
    [self addChild:content];
    [self setContentSize:CGSizeMake(217, 135)];
    [self setAnchorPoint:CGPointMake(0.5, 0.5)];

}

-(void)onEnter{
    [super onEnter];
    //[self runAction:[CCScaleTo actionWithDuration:ANIMATION_DELAY scale:1]];
}

-(void)scaleOut{
    world->DestroyBody(body);
    [self runAction:[CCScaleTo actionWithDuration:ANIMATION_DELAY scale:0]];
    [CCCallFunc actionWithTarget:self selector:@selector(remove)];
}

-(CCNode*)visualNode{
    return self;
}

-(void)remove{
    [self removeFromParentAndCleanup:YES];    
}

-(void)dealloc{
    self.emailId = nil;
    body = nil;
    world = nil;
    [title release];
    [content release];
    [super dealloc];
}

@end
