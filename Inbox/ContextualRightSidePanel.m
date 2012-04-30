//
//  ContextualRightSidePanel.m
//  Inbox
//
//  Created by Simon Watiau on 4/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ContextualRightSidePanel.h"
#import "CCLayer.h"
#import "cocos2d.h"
#define SLIDE_DURATION 1
@implementation ContextualRightSidePanel


-(id)initWithLayer:(CCLayer*)l{
    if (self = [super init]){
        layer = l;
        isHidden = false;
    }
    return self;
}

-(void)onEnter{
    [super onEnter];
    [self refreshPositionAnimated:NO];
}

-(void)refreshPositionAnimated:(BOOL)animated{
    self.contentSize = CGSizeMake(300, layer.contentSize.height);
    self.anchorPoint = CGPointMake(0, 0);
    if (isHidden){
        if (animated){
            [self runAction:[CCMoveTo actionWithDuration:SLIDE_DURATION position:CGPointMake(1024, 0)]];
        }else{
            self.position = CGPointMake(1024, 0);
        }
    }else{
        if (animated){
            [self runAction:[CCMoveTo actionWithDuration:SLIDE_DURATION position:CGPointMake(1024-300, 0)]];
        }else{
            self.position = CGPointMake(1024-300, 0);
        }
    }
}

-(void)showAnimated:(BOOL)animated{
    isHidden = false;
    [self refreshPositionAnimated:animated];
}

-(void)hideAnimated:(BOOL)animated{
    isHidden = true;
    [self refreshPositionAnimated:animated];
}

@end
