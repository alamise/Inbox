#import "InboxStack.h"
#import "cocos2d.h"
#import "Box2D.h"
#import "config.h"
#import "EmailNode.h"
@implementation InboxStack

-(id)initWithWorld:(b2World*)w{
    if (self = [super init]){
        world = w;
    }
    return self;
}


-(void)dealloc{
    [super dealloc];
}


-(EmailNode*)addEmail:(EmailModel*)emailModel{
    return [self addEmail:emailModel onPoint:CGPointMake(150, 350)];
}


-(EmailNode*)addEmail:(EmailModel *)emailModel onPoint:(CGPoint)point{
    b2BodyDef bodyDef;
    
	bodyDef.position.Set(point.x/PTM_RATIO,point.y/PTM_RATIO);
    bodyDef.linearDamping = 10;
    bodyDef.linearVelocity = [self getLinearVelocityVector];
    bodyDef.angularDamping = 4;
    bodyDef.angularVelocity=[self getAngularVelocity];
    
    EmailNode* node = [[EmailNode alloc] initWithEmailModel:emailModel bodyDef:bodyDef world:world];
    return node;
}

-(float)getAngularVelocity{
    int range=1;
    float v = arc4random() % (2*range);
    return v-range;
}

-(b2Vec2)getLinearVelocityVector{
    double angle = arc4random() % 360;
    int distance = 20;
    float x = distance*cos(angle);
    float y = distance*sin(angle);
    return b2Vec2(x,y);
}

@end
