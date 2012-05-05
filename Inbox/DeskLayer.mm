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
#import "ContextualRightSidePanel.h"
#import "FoldersTable.h"
#define ANIMATION_DELAY 0.2
#define SCROLL 23435543



@interface DeskLayer() 
@end

@implementation DeskLayer

-(id) initWithDelegate:(id<DeskProtocol>)d{
	if( (self=[super init])) {
        delegate = d;
        self.isTouchEnabled = YES;
		self.isAccelerometerEnabled = NO;
		[self schedule: @selector(tick:)];
        interactionsManager = [[InteractionsManager alloc] initWithDelegate:self];
        drawingManager = [[DrawingManager alloc] initWithDelegate:self];
        
        foldersTable = [[FoldersTable alloc] init];

        //[self offlineTests];
	}
	return self;
}

-(void)registerWithTouchDispatcher {
    [[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:interactionsManager priority:1 swallowsTouches:NO];
}

- (void) dealloc{
    [interactionsManager release];
    [drawingManager release];
	[super dealloc];
}

-(void)offlineTests{
    NSManagedObjectContext* context=[((AppDelegate*)[UIApplication sharedApplication].delegate) newManagedObjectContext];
    for (int i=0;i<5;i++){
        EmailModel* email = [NSEntityDescription insertNewObjectForEntityForName:[EmailModel entityName] inManagedObjectContext:context];
        [self putEmail:email];
    }  

    NSMutableArray* ff = [NSMutableArray array];
    for (int i=0;i<5;i++){
        FolderModel* folder = [NSEntityDescription insertNewObjectForEntityForName:[FolderModel entityName] inManagedObjectContext:context];
        [ff addObject:folder];
    }
    //[table setFolders:ff];
}

-(CCLayer*)layer {
    return self;
}

-(b2World*)world{
    return interactionsManager.world;
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

-(void)showFolders:(NSArray*)folders{
    [self showFolders_hideAndSet:folders];
}

-(void)showFolders_hideAndSet:(NSArray *)folders{
    if (!drawingManager.rightSidePanel.isHidden){
        [drawingManager.rightSidePanel hideAnimated:YES callback:^{
            if (!foldersTable.view.parent){
                [self addChild:foldersTable.view];
            }
            [drawingManager.rightSidePanel setController:foldersTable];        
            [foldersTable setFolders:folders];
            [self showFolders_show];
        }];
    }else{
        if (!foldersTable.view.parent){
            [self addChild:foldersTable.view];
        }
        [drawingManager.rightSidePanel setController:foldersTable];
        [self showFolders_show];
    }
}

-(void)showFolders_show{
    [drawingManager.rightSidePanel showAnimated:YES callback:nil];
}

-(void) interactionStarted{
}

-(void) interactionEnded{
    
}

#pragma mark - draw battlefield

-(void) draw{
    [interactionsManager drawDebugData];
}

-(void)refresh{
    [interactionsManager refresh];
    [drawingManager refresh];
}

-(void)settingsButtonTapped {
    [delegate openSettings];
}

-(int)elementsOnTheDesk{
    return [interactionsManager.visibleNodes count];
}

-(BOOL) element:(id<ElementNodeProtocol>)element droppedAt:(CGPoint)point{
    
}

-(void)cleanDesk{
    for (EmailNode* node in interactionsManager.visibleNodes){
        [interactionsManager unregisterNode:node];
        CCFiniteTimeAction* scale = [CCScaleTo actionWithDuration:ANIMATION_DELAY scale:0];
        CCFiniteTimeAction* callback = [CCCallBlock actionWithBlock:^{
            [drawingManager removeChildAndBody:node];
        }];
        
        CCAction* sequence = [CCSequence actionOne:scale two:callback];
        [node runAction:sequence];
    }
    [self setPercentage:0 labelCount:0];
}

-(void) tick: (ccTime) dt{
	[interactionsManager tick:dt];
}

@end
