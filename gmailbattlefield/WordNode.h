//
//  WordNode.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CCNode.h"
@class CCLabelTTF;
@interface WordNode : CCNode{
    NSString* word;
    CCLabelTTF *label;
}
@property(nonatomic,retain) NSString* word;
- (id)initWithWord:(NSString*)word;
@end
