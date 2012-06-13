#import "CCNode.h"
#import "Box2D.h"
#import <CoreData/CoreData.h>
#import "ElementNodeProtocol.h"

@class CCLabelTTF,EmailModel;
@interface EmailNode : CCNode<ElementNodeProtocol>{
    NSManagedObjectID* emailId;
    CCLabelTTF *title;
    CCLabelTTF *content;
    BOOL didMoved;
    b2Body* body;
    b2World* world;
}
@property(nonatomic,readonly,retain) NSManagedObjectID* emailId;
@property(nonatomic,assign) BOOL didMoved;
@property(nonatomic,assign) BOOL isAppearing;
@property(nonatomic,assign) BOOL isDisappearing;

+ (int)ANIMATION_DURATION;

- (id) initWithEmailModel:(EmailModel *)model bodyDef:(b2BodyDef)bodyDef world:(b2World *)world;
- (void) scaleOut;


@end
