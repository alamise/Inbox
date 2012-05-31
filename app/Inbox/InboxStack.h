#import "CCNode.h"
#import "cocos2d.h"
#import "Box2D.h"
@class EmailModel,EmailNode;
@interface InboxStack : NSObject{
    b2World* world;
}
-(id)initWithWorld:(b2World*)w;
-(EmailNode*)addEmail:(EmailModel*)emailModel;
-(EmailNode*)addEmail:(EmailModel *)emailModel onPoint:(CGPoint)point;
@end
