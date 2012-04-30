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

#import "DeskLayer.h"
#import "CTCoreAccount.h"
#import "CCNode.h"
#import "EmailNode.h"
#import "DeskProtocol.h"
#import "models.h"
#import "GLES-Render.h"
#import "EmailModel.h"
#import "FolderModel.h"
#import "config.h"
#import "ProgressIndicator.h"
#import "InboxStack.h"
#import "AppDelegate.h"
#import "InteractionsManager.h"
#import "DrawingManager.h"

#define ANIMATION_DELAY 0.2
#define SCROLL 23435543



@interface DeskLayer() 
@end

@implementation DeskLayer
@synthesize folders;

-(id) initWithDelegate:(id<DeskProtocol>)d{
	if( (self=[super init])) {
        delegate = d;
        self.isTouchEnabled = YES;
		self.isAccelerometerEnabled = NO;
		folders = nil;
		[self schedule: @selector(tick:)];
        interactionsManager = [[InteractionsManager alloc] initWithDelegate:self];
        drawingManager = [[DrawingManager alloc] initWithDelegate:self];
        [self offlineTests];
	}
	return self;
}

-(void)registerWithTouchDispatcher {
    [[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:1 swallowsTouches:NO];
}

- (void) dealloc{
    [interactionsManager release];
    [drawingManager release];
    
    [delegate release];
    [indicator release];
    [interactionsManager release];
	[super dealloc];
}

-(void)offlineTests{
    NSManagedObjectContext* context=[((AppDelegate*)[UIApplication sharedApplication].delegate) newManagedObjectContext];
    for (int i=0;i<5;i++){
        EmailModel* email = [NSEntityDescription insertNewObjectForEntityForName:[EmailModel entityName] inManagedObjectContext:context];
        [self putEmail:email];
    }
}

-(CCLayer*)layer {
    return self;
}

-(b2World*)world{
    return interactionsManager.world;
}
#pragma mark right views (folders, etc..)

-(void)setFolders:(NSArray *)f{
    BOOL shouldScrollToTop = true;
    if (folders){
        shouldScrollToTop=false;
        [folders autorelease];
        folders = nil;
    }
    folders = [f retain];
    [foldersTable reloadData];
    if (shouldScrollToTop){
        [foldersTable scrollToTop];
    }
}

-(void)foldersHidden:(BOOL)hidden animated:(BOOL)animated{
    
    if (!foldersTable){
        return;
    }
    CGSize windowSize = [CCDirector sharedDirector].winSize;
    CGPoint newPos;
    if (hidden){
        newPos = CGPointMake(windowSize.width, 0);
    }else{
        newPos = CGPointMake(windowSize.width-240, 0);
    }
    if (CGPointEqualToPoint(foldersTable.position,newPos) == NO){
        if (animated){
            [foldersTable runAction:[CCMoveTo actionWithDuration:ANIMATION_DELAY position:newPos]];
        }else{
            foldersTable.position=newPos;
        }
    }
}

#pragma mark add/remove/change elements methods

-(void) putEmail:(EmailModel*)model{
    id<ElementNodeProtocol> node = [drawingManager.inboxStack addEmail:model];
    [self addChild:[node visualNode]];
    [interactionsManager registerNode:node];
}

-(void)setPercentage:(float)percentage labelCount:(int)count{
    [drawingManager.progressIndicator setPercentage:percentage labelCount:count];
}



#pragma mark - drag & drop

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
    return [interactionsManager ccTouchBegan:touch withEvent:event];
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
    [interactionsManager ccTouchMoved:touch withEvent:event];
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
    [interactionsManager ccTouchEnded:touch withEvent:event];
}
-(void) elementTouched:(id<ElementNodeProtocol>)element{
    if ([element isKindOfClass:[EmailNode class]]){
        [delegate emailTouched:((EmailNode*)element).email];
    }
}

-(BOOL) element:(id<ElementNodeProtocol>)element droppedAt:(CGPoint)point{
    SWTableView* table = (SWTableView*)[self getChildByTag:SCROLL];
    int cellIndex = [table cellIndexAt:point];
    if (cellIndex!=-1){
        FolderModel* folder = [self.folders objectAtIndex:cellIndex];
        if ([element isKindOfClass:[EmailNode class]]){
            [delegate moveEmail:((EmailNode*)element).email toFolder:folder];
        }
        [element scaleOut];
        return false;
    }
    return true;
}

-(void) interactionStarted{
}

-(void) interactionEnded{
    
}

#pragma mark - draw battlefield

-(void) draw{
    [interactionsManager drawDebugData];
}

-(void)setOrUpdateScene{
    [interactionsManager refresh];
    [drawingManager refresh];
    [self putFoldersZones];
}

-(void)settingsButtonTapped {
    [delegate openSettings];
}



-(int)mailsOnSceneCount{
    return [interactionsManager.visibleNodes count];
}

//
//-(void)cleanDesk{
//    for (EmailNode* node in draggableNodes){
//        [node scaleAndHide];
//    }
//    [draggableNodes removeAllObjects];
//    ProgressIndicator* indicator = (ProgressIndicator*)[self getChildByTag:tagProgressIndicator];
//}

-(void)progressIndicatorHidden:(BOOL)hidden animated:(BOOL)animated{
    if (!indicator){
        return;
    }
    int newScale;
    if (hidden){
        newScale = 0;
    }else{
        newScale = 1;
    }
    if (indicator.scale != newScale){
        if (animated){
           [indicator runAction:[CCScaleTo actionWithDuration:ANIMATION_DELAY scale:newScale]]; 
        }else{
            indicator.scale=newScale;
        }
    }
}

-(void) tick: (ccTime) dt{
	[interactionsManager tick:dt];
}

@end
