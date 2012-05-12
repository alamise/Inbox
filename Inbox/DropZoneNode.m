/*
 *
 * Copyright (c) 2012 Simon Watiau.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

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
