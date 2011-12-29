//
//  DropZoneNode.m
//  Inbox
//
//  Created by Simon Watiau on 12/27/11.
//

#import "DropZoneNode.h"
#import "cocos2d.h"
@interface DropZoneNode()
@property(nonatomic,retain) CCLabelTTF* label;
@end

@implementation DropZoneNode
@synthesize label,folderPath;
-(id)init{
    if (self = [super init]){
        drawMe = true;
        self.folderPath=@"";
    }
    return self;
}

-(void) draw {
    [super draw];
    if (drawMe){
        drawMe = false;
        CCSprite* sprite = [CCSprite spriteWithFile:@"circle.png"];
        sprite.anchorPoint = CGPointMake(0, 0);
        sprite.position=CGPointMake(0,0);
        [self addChild:sprite];


        sprite = [CCSprite spriteWithFile:@"sticker.png"];
        sprite.anchorPoint = CGPointMake(0, 0);
        sprite.position=CGPointMake(0,150);
        [self addChild:sprite];
        
        label = [[CCLabelTTF labelWithString:[self readableLabelForPath:self.folderPath] dimensions:CGSizeMake(185, 90) alignment:UITextAlignmentCenter lineBreakMode:UILineBreakModeTailTruncation fontName:@"Arial" fontSize:30] retain];
        label.position = CGPointMake(8, 145);
        label.color=ccc3(0, 0, 0);
        label.anchorPoint=CGPointMake(0, 0);
        [self addChild:label];

        [self setAnchorPoint:CGPointMake(0, 0)];

        [self setContentSize:CGSizeMake(200, 250)];
    }
}

-(NSString*)readableLabelForPath:(NSString*)path{
    NSString* str=path;
    if ([path hasPrefix:@"[Gmail]"]){
        str = [path substringFromIndex:8];
    }
    if ([str isEqualToString:@"All Mail"]){
        return @"Archive";
    }
    return str;
}
@end
