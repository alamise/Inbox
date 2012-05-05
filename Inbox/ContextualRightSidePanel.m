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
#import "CCActionInstant.h"

#define SLIDE_DURATION 0.3
@implementation ContextualRightSidePanel
@synthesize isHidden;

-(id)initWithLayer:(CCLayer*)l{
    if (self = [super init]){
        layer = l;
        isHidden = false;
    }
    return self;
}

-(void)dealloc{
    [controller release];
    [super dealloc];
}

-(void)setController:(id<CCController>)c{
    [controller autorelease];
    controller = [c retain];
    [self refreshPositionAnimated:NO callback:nil];
}

-(void)refreshPositionAnimated:(BOOL)animated callback:(void(^)())callback{
    if (!callback){
        callback = ^{};
    }
    if (isHidden){
        if (animated){
            CCSequence* sequence = [[CCSequence alloc] initOne:[CCMoveTo actionWithDuration:SLIDE_DURATION position:CGPointMake(1024, 0)]
                                    two:[CCCallBlock actionWithBlock:callback]];
            [controller.view runAction:sequence];
        }else{
            controller.view.position = CGPointMake(1024, 0);
            callback();
        }
    }else{
        if (animated){
            CCSequence* sequence = [[CCSequence alloc]
                                    initOne:
                                    [CCMoveTo actionWithDuration:SLIDE_DURATION position:CGPointMake(1024 - 240, 0)]
                                    two:[CCCallBlock actionWithBlock:callback]];
            [controller.view runAction:sequence];
        }else{
            controller.view.position = CGPointMake(1024-240, 0);
            callback();
        }
    }
}


-(void)showAnimated:(BOOL)animated callback:(void(^)())callback{
    isHidden = false;
    [self refreshPositionAnimated:animated callback:callback];
}

-(void)hideAnimated:(BOOL)animated callback:(void(^)())callback{
    isHidden = true;
    [self refreshPositionAnimated:animated callback:callback];
}

@end
