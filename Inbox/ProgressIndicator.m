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

#import "ProgressIndicator.h"

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

-(void)setProgressTo:(int)count outOf:(int)total{
    [progressTimer setPercentage:100-(count*total)/100];
    
    [label setString:[NSString stringWithFormat:@"%d",total-count]];
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
