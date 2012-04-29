//
//  InboxStack.m
//  Inbox
//
//  Created by Simon Watiau on 4/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "InboxStack.h"
#import "cocos2d.h"
#import "Box2D.h"
#import "GameConfig.h"
#import "EmailNode.h"
@implementation InboxStack


-(id)initWithWorld:(b2World*)w{
    if (self = [super init]){
        elements = [[NSMutableArray alloc] init];
        world = w;
    }
    [self setContentSize:CGSizeMake(400, 400)];
    [self setAnchorPoint:CGPointMake(0.5, 0.5)];
    return self;
}


-(void)dealloc{
    [elements release];
    [super dealloc];
}


-(EmailNode*)addEmail:(EmailModel*)emailModel{
    b2BodyDef bodyDef;
	bodyDef.position.Set(400/2/PTM_RATIO, 400/2/PTM_RATIO);
    bodyDef.linearDamping=1.4;
    EmailNode* node = [[EmailNode alloc] initWithEmailModel:emailModel bodyDef:bodyDef world:world];
    [self addChild:node z:4587645];
    return node;
}

@end
