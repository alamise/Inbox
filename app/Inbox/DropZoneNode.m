#import "DropZoneNode.h"
#import "cocos2d.h"
#import "FolderModel.h"
@interface DropZoneNode()
@property(nonatomic,retain) CCLabelTTF* label;
@end

@implementation DropZoneNode
@synthesize label,title;
-(id)init{
    if (self = [super init]){
        drawMe = true;
        self.title=@"";
    }
    return self;
}

-(void)setTitle:(NSString *)t{
    [title autorelease];
    title =[t retain];
    [label setString:title];
}

-(void) draw {
    [super draw];
    if (drawMe){
        drawMe = false;
        CCSprite* sprite = [CCSprite spriteWithFile:@"circle.png"];
        sprite.anchorPoint = CGPointMake(0, 0);
        sprite.position=CGPointMake(20,0);
        [self addChild:sprite];


        sprite = [CCSprite spriteWithFile:@"sticker.png"];
        sprite.anchorPoint = CGPointMake(0, 0);
        sprite.position=CGPointMake(20,150);
        [self addChild:sprite];
        
        label = [[CCLabelTTF labelWithString:self.title dimensions:CGSizeMake(185, 90) alignment:UITextAlignmentCenter lineBreakMode:UILineBreakModeTailTruncation fontName:@"Arial" fontSize:30] retain];
        label.position = CGPointMake(28, 145);
        label.color=ccc3(0, 0, 0);
        label.anchorPoint=CGPointMake(0, 0);
        [self addChild:label];

        [self setAnchorPoint:CGPointMake(0, 0)];

        [self setContentSize:CGSizeMake(240, 250)];
    }
}

+ (CGPoint) visualCenterFromRealCenter:(CGPoint)point{
    return ccpAdd(point, CGPointMake(2, 2));
}


+(CGSize) fullSize{
return CGSizeMake(240, 250);
}


@end
