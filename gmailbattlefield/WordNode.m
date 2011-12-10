//
//  WordNode.m
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/30/11.
//

#import "WordNode.h"
#import "cocos2d.h"
@implementation WordNode
@synthesize word;

- (id)initWithWord:(NSString*)w{
    self = [super init];
    if (self) {
        word = [w retain];
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
        label = [[CCLabelTTF labelWithString:word fontName:@"Arial" fontSize:24] retain];
        label.color=ccc3(0, 1, 0);
        label.position=CGPointMake(50, 50);
        [self addChild:sprite];
        [self addChild:label];
        [self setContentSize:CGSizeMake(100, 100)];
        [self setAnchorPoint:CGPointMake(0.5, 0.5)];
    }
}

-(void)setWord:(NSString *)w{
    if (word){
        [word release];
    }
    if (w){
        word = [w retain];
        [label setString:word];
    }else{
        word=nil;
    }
    
}
-(void)dealloc{
    self.word=nil;
    [label release];
    [super dealloc];
}

@end
