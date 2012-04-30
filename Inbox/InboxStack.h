//
//  InboxStack.h
//  Inbox
//
//  Created by Simon Watiau on 4/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CCNode.h"
#import "cocos2d.h"
#import "Box2D.h"
@class EmailModel,EmailNode;
@interface InboxStack : NSObject{
    CCLayer* ground;
    b2World* world;
}
-(id)initWithGround:(CCLayer*)node world:(b2World*)world;
-(EmailNode*)addEmail:(EmailModel*)emailModel;
@end
