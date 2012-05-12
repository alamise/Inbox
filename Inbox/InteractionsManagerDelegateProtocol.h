//
//  InteractionsManagerDelegateProtocol.h
//  Inbox
//
//  Created by Simon Watiau on 4/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ElementNodeProtocol.h"
#import "cocos2d.h"
@protocol InteractionsManagerDelegateProtocol <NSObject>
-(CCLayer*) layer;
-(void) elementTouched:(id<ElementNodeProtocol>)element;
-(BOOL) element:(id<ElementNodeProtocol>)element droppedAt:(CGPoint)point;
-(void) interactionStarted;
-(void) interactionEnded;
-(void) longTouchOnPoint:(CGPoint)point;
@end
