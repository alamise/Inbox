//
//  EmailModel.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/30/11.
//

#import "CCNode.h"
#import "Box2D.h"
@class CCLabelTTF,EmailModel;
@interface EmailNode : CCNode{
    EmailModel* emailModel;
    CCLabelTTF *title;
    CCLabelTTF *content;
    BOOL drawMe;
    BOOL didMoved;
    b2Body* body;
    b2World* world;
}
@property(nonatomic,retain) EmailModel* emailModel;
@property(nonatomic,assign) BOOL didMoved;
@property(nonatomic,assign) BOOL isAppearing;
@property(nonatomic,assign) BOOL isDisappearing;
- (id)initWithEmailModel:(EmailModel*)model bodyDef:(b2BodyDef)bodyDef world:(b2World*)world;
-(void)fadeAndHide;
-(void)scaleAndHide;
@end
