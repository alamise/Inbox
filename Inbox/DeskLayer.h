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
#import "cocos2d.h"
#import "Box2D.h"
#import "DeskProtocol.h"
#import "DropZoneNode.h"
#import "SWTableView.h"
#import "GLES-Render.h"
#import "ProgressIndicator.h"

@class EmailNode, EmailModel, SWTableView;

@interface DeskLayer : CCLayer<SWTableViewDataSource>{
	b2World* world;
	GLESDebugDraw *m_debugDraw;
    NSMutableArray *draggableNodes;
    EmailNode *draggedNode;
    id<DeskProtocol> delegate;
    CGPoint lastTouchPosition;
    NSTimeInterval lastTouchTime;
    SWTableView* foldersTable;
    ProgressIndicator* indicator;
    NSArray* folders;
    BOOL isActive;
}
@property(assign) BOOL isActive;
@property(nonatomic,retain) NSArray* folders;
-(id) initWithDelegate:(id<DeskProtocol>)d;
-(void) putEmail:(EmailModel*)model;
-(void) checkNodesCoords;
-(void) cleanDesk;
-(void) setOrUpdateScene;
-(void)setPercentage:(float)percentage labelCount:(int)count;
-(int) mailsOnSceneCount;
-(void)cleanDesk;
-(void)progressIndicatorHidden:(BOOL)hidden animated:(BOOL)animated;
-(void)foldersHidden:(BOOL)hidden animated:(BOOL)animated;
@end

