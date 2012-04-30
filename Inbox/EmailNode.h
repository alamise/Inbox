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

#import "CCNode.h"
#import "Box2D.h"
#import <CoreData/CoreData.h>
#import "ElementNodeProtocol.h"

@class CCLabelTTF,EmailModel;
@interface EmailNode : CCNode<ElementNodeProtocol>{
    EmailModel* email;
    CCLabelTTF *title;
    CCLabelTTF *content;
    BOOL didMoved;
    b2Body* body;
    b2World* world;
}
@property(nonatomic,retain) EmailModel* email;
@property(nonatomic,assign) BOOL didMoved;
@property(nonatomic,assign) BOOL isAppearing;
@property(nonatomic,assign) BOOL isDisappearing;
- (id)initWithEmailModel:(EmailModel*)model bodyDef:(b2BodyDef)bodyDef world:(b2World*)world;
-(void)scaleOut;
@end
