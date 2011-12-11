//
//  WordNode.m
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/30/11.
//
#import "EmailNode.h"
#import "EmailModel.h"
#import "cocos2d.h"
@implementation EmailNode
@synthesize emailModel;

- (id)initWithEmailModel:(EmailModel*)model{
    self = [super init];
    if (self) {
        emailModel = [model retain];
        drawMe = true;
    }
    return self;    
}

-(void) draw {
    [super draw];
    if (drawMe){
        drawMe = false;
        NSLog(@"draw");
        CCSprite* sprite = [CCSprite spriteWithFile:@"round.png"];
        sprite.position=CGPointMake(50,50);
        label = [[CCLabelTTF labelWithString:emailModel.senderName fontName:@"Arial" fontSize:24] retain];
        label.color=ccc3(0, 1, 0);
        label.position=CGPointMake(50, 50);
        [self addChild:sprite];
        [self addChild:label];
        [self setContentSize:CGSizeMake(100, 100)];
        [self setAnchorPoint:CGPointMake(0.5, 0.5)];
    }
}

-(void)setEmailModel:(EmailModel *)model{
    if (emailModel){
        [emailModel release];
    }
    if (model){
        emailModel = [model retain];
        [label setString:emailModel.senderName];
    }else{
        emailModel=nil;
    }
    
}
-(void)dealloc{
    self.emailModel=nil;
    [label release];
    [super dealloc];
}

@end
