#import "ProgressIndicator.h"
#define ANIMATION_DELAY 0.4
@implementation ProgressIndicator

-(id)init{
    if (self = [super init]){
        drawMe = true;
        progressTimer = [[CCProgressTimer progressWithFile:@"progressActivityForeground.png"] retain];
        progressTimer.type = kCCProgressTimerTypeRadialCCW;
        label = [CCLabelTTF labelWithString:@"----" fontName:@"Arial" fontSize:40];
        label.color = ccc3(1, 1, 1);
    }
    return self;
}

-(void)dealloc{
    [label release];
    [progressTimer release];
    [super dealloc];
}

-(void)setPercentage:(float)percentage labelCount:(int)count{
    [progressTimer setPercentage:100-percentage];
    if (count==-1){
        [label setString:@"----"];
    }else{
        [label setString:[NSString stringWithFormat:@"%d",count]];
    }
    
}


-(void) draw {
    [super draw];
    if (drawMe){
        drawMe = false;
        CCSprite* background = [CCSprite spriteWithFile:@"progressActivityBackground.png"];
        [self addChild:background];
        [self addChild:progressTimer];
        progressTimer.position = CGPointMake(0, 0);
        [self addChild:label];
    }
}
@end
