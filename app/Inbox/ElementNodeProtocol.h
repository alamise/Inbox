//
//  ElementNodeProtocol.h
//  Inbox
//
//  Created by Simon Watiau on 4/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CCNode;
@protocol ElementNodeProtocol <NSObject>
    -(CCNode*) visualNode;
    -(void)scaleOut;
@end
