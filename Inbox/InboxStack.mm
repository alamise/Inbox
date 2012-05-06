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
#import "config.h"
#import "EmailNode.h"
@implementation InboxStack

-(id)initWithWorld:(b2World*)w{
    if (self = [super init]){
        world = w;
    }
    return self;
}


-(void)dealloc{
    [super dealloc];
}


-(EmailNode*)addEmail:(EmailModel*)emailModel{
    b2BodyDef bodyDef;
    
	bodyDef.position.Set(150/PTM_RATIO,400/PTM_RATIO);
    bodyDef.linearDamping=10;
    bodyDef.linearVelocity = [self getLinearVelocityVector];
    bodyDef.angularDamping=4;
    bodyDef.angularVelocity=[self getAngularVelocity];
    
    EmailNode* node = [[EmailNode alloc] initWithEmailModel:emailModel bodyDef:bodyDef world:world];
    return node;
}

-(float)getAngularVelocity{
    int range=1;
    float v = arc4random() % (2*range);
    return v-range;
}

-(b2Vec2)getLinearVelocityVector{
    double angle = arc4random() % 360;
    int distance = 20;
    float x = distance*cos(angle);
    float y = distance*sin(angle);
    return b2Vec2(x,y);
}

@end
