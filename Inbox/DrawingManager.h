//
//  DrawingManager.h
//  Inbox
//
//  Created by Simon Watiau on 4/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "DrawingManagerDelegateProtocol.h"

@class InboxStack, ProgressIndicator,ContextualRightSidePanel;

@interface DrawingManager : NSObject{
    CCLayer* layer;
    b2World* world;
    InboxStack* inboxStack;
    ProgressIndicator* progressIndicator;
    ContextualRightSidePanel* rightSidePanel;
    id<DrawingManagerDelegateProtocol> delegate;
    

}
@property(readonly) InboxStack* inboxStack;
@property(readonly) ProgressIndicator* progressIndicator;
@property(readonly) ContextualRightSidePanel* rightSidePanel;

-(id) initWithDelegate:(id<DrawingManagerDelegateProtocol>)d;
-(void) removeChildAndBody:(CCNode*)node;
-(void) refresh;
@end
