#import "cocos2d.h"
@interface ProgressIndicator : CCNode{
    BOOL drawMe;
    CCProgressTimer* progressTimer;
    CCLabelAtlas* label;
    
}
-(void)setPercentage:(float)percentage labelCount:(int)count;
@end
