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
    CCLabelTTF *label;
    BOOL drawMe;
}
@property(nonatomic,retain) EmailModel* emailModel;
- (id)initWithEmailModel:(EmailModel*)model;
@end
