//
//  DrawingManagerDelegateProtocol.h
//  Inbox
//
//  Created by Simon Watiau on 4/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Box2D.h"

@protocol DrawingManagerDelegateProtocol <NSObject>
-(b2World*) world;
-(CCLayer*) layer;
-(void)settingsButtonTapped;
@end
