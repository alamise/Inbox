//
//  EmailModel.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/30/11.
//

#import "CCNode.h"
#import "EmailModel.h"
@class CCLabelTTF;
@interface EmailNode : CCNode{
    EmailModel* emailModel;
    CCLabelTTF *title;
    CCLabelTTF *content;
    BOOL drawMe;
    BOOL didMoved;
}
@property(nonatomic,retain) EmailModel* emailModel;
@property(nonatomic,assign) BOOL didMoved;
- (id)initWithEmailModel:(EmailModel*)model;

@end
