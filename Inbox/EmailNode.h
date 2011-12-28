//
//  EmailModel.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/30/11.
//

#import "CCNode.h"
#import "VisualEffectProtocol.h"
@class CCLabelTTF,EmailModel;
@interface EmailNode : CCNode<VisualEffectProtocol>{
    EmailModel* emailModel;
    CCLabelTTF *title;
    CCLabelTTF *content;
    BOOL drawMe;
    BOOL didMoved;
    BOOL isAppearing;
    BOOL isDisappearing;
}
@property(nonatomic,retain) EmailModel* emailModel;
@property(nonatomic,assign) BOOL didMoved;
@property(nonatomic,assign) BOOL isAppearing;
@property(nonatomic,assign) BOOL isDisappearing;
- (id)initWithEmailModel:(EmailModel*)model;
-(void)hideAndRemove;
@end
