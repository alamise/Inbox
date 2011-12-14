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
@synthesize emailModel,didMoved;

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
        CCSprite* sprite = [CCSprite spriteWithFile:@"emailBackground.png"];
        sprite.position=CGPointMake(100,55);
        [self addChild:sprite];
        

        title = [[CCLabelTTF labelWithString:emailModel.senderName dimensions:CGSizeMake(170, 20) alignment:UITextAlignmentLeft lineBreakMode:UILineBreakModeClip fontName:@"Arial" fontSize:15] retain];
        title.color=ccc3(150, 150, 150);
        title.position=CGPointMake(100, 88);
        [self addChild:title];
        
        content = [[CCLabelTTF labelWithString:emailModel.summary dimensions:CGSizeMake(170, 65) alignment:UITextAlignmentLeft lineBreakMode:UILineBreakModeClip fontName:@"Arial" fontSize:13] retain];

        content.color=ccc3(0, 1, 0);
        content.position=CGPointMake(100, 48);
        
        [self addChild:content];
        [self setContentSize:CGSizeMake(200, 110)];
        [self setAnchorPoint:CGPointMake(0.5, 0.5)];
    }
}

-(void)setEmailModel:(EmailModel *)model{
    if (emailModel){
        [emailModel release];
    }
    if (model){
        emailModel = [model retain];
        [title setString:emailModel.senderName];
    }else{
        emailModel=nil;
    }
    
}
-(void)dealloc{
    self.emailModel=nil;
    [title release];
    [content release];
    [super dealloc];
}

@end
