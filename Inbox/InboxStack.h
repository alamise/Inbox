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
    b2World* world;
}
-(id)initWithWorld:(b2World*)w;
-(EmailNode*)addEmail:(EmailModel*)emailModel;
@end
