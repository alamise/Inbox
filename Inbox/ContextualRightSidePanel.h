//
//  ContextualRightSidePanel.h
//  Inbox
//
//  Created by Simon Watiau on 4/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CCNode.h"
#import "CCLayer.h"
#import "CCController.h"
@interface ContextualRightSidePanel : NSObject{
    CCLayer* layer;
    BOOL isHidden;
    id<CCController> controller;
}
@property(readonly) BOOL isHidden;
-(id)initWithLayer:(CCLayer*)l;
-(void)refreshPositionAnimated:(BOOL)animated callback:(void(^)())callback;

-(void)showAnimated:(BOOL)animated callback:(void(^)())callback;
-(void)hideAnimated:(BOOL)animated callback:(void(^)())callback;
-(void)setController:(id<CCController>)controller;
@end
