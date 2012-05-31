#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Box2D.h"

@protocol DrawingManagerDelegateProtocol <NSObject>
-(b2World*) world;
-(CCLayer*) layer;
-(void)settingsButtonTapped;
@end
