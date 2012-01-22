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

@interface DropZoneNode()
@property(nonatomic,retain) CCLabelTTF* label;
-(NSString*)readableLabelForPath:(NSString*)path;
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
    if ([path hasPrefix:@"[Gmail]/"]){
        str = [path substringFromIndex:8];
    }
    if ([str isEqualToString:@"All Mail"]){
        return @"Archive";
    }
    return str;
}
@end
