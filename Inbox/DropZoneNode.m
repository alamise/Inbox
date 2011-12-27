//
//  DropZoneNode.m
//  Inbox
//
//  Created by Simon Watiau on 12/27/11.
//

#import "DropZoneNode.h"
#import "cocos2d.h"
@implementation DropZoneNode

-(id)init{
    if (self = [super init]){
        drawMe = true;
    }
    return self;
}

-(void) draw {
    [super draw];
    if (drawMe){
        drawMe = false;
        CCSprite* sprite = [CCSprite spriteWithFile:@"circle.png"];
        sprite.anchorPoint = CGPointMake(0, 0);
        sprite.position=CGPointMake(0,0);
        [self addChild:sprite];
        [self setContentSize:CGSizeMake(200, 200)];
        [self setAnchorPoint:CGPointMake(0, 0)];
    }
}

@end
