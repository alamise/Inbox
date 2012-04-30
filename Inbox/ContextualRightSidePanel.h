//
//  ContextualRightSidePanel.h
//  Inbox
//
//  Created by Simon Watiau on 4/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CCNode.h"
#import "CCLayer.h"

@interface ContextualRightSidePanel : CCNode{
    CCLayer* layer;
    BOOL isHidden;
}
-(id)initWithLayer:(CCLayer*)l;
-(void)refreshPositionAnimated:(BOOL)animated;

-(void)showAnimated:(BOOL)animated;
-(void)hideAnimated:(BOOL)animated;

@end
