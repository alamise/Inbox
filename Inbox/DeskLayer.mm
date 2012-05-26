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
#import "NSArray+CoreData.h"
#import "Deps.h"

#define ANIMATION_DELAY 0.2
#define SCROLL 23435543
static int zIndex = INT_MAX;


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
    NSManagedObjectContext* context=[[Deps sharedInstance].coreDataManager mainContext];
    for (int i=0;i<5;i++){
        EmailModel* email = [NSEntityDescription insertNewObjectForEntityForName:[EmailModel entityName] inManagedObjectContext:context];
        [self putEmail:email];
    }  
}

-(void)onEnter{
    [super onEnter];
    //[self offlineTests];
    return;
    NSManagedObjectContext* context = [[Deps sharedInstance].coreDataManager mainContext];
    NSMutableArray* ff = [NSMutableArray array];
    for (int i=0;i<5;i++){
        FolderModel* folder = [NSEntityDescription insertNewObjectForEntityForName:[FolderModel entityName] inManagedObjectContext:context];
        [ff addObject:folder];
    }
    [self performSelector:@selector(showFolders:) withObject:ff afterDelay:1];
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
    [self addChild:[node visualNode] z:zIndex--]; // until I find a better solution :(
    [self sortAllChildren];
    [interactionsManager registerNode:node];
}

-(void)setPercentage:(float)percentage labelCount:(int)count{
    [drawingManager.progressIndicator setPercentage:percentage labelCount:count];
}

#pragma mark - drag & drop

-(void)showFolders:(NSArray*)folders{
    NSArray* currentFolders = foldersTable.folders;
    NSArray* newFolders = [folders ArrayOfManagedIds];
    NSLog(@"%@",currentFolders);
    NSLog(@"%@",newFolders);
    if (![currentFolders isEqualToArray:newFolders]){
        [self showFolders_hideAndSet:newFolders];
    }
}

-(void)showFolders_hideAndSet:(NSArray *)folders{
    if (!drawingManager.rightSidePanel.isHidden){
        [drawingManager.rightSidePanel hideAnimated:NO callback:^{
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
    [drawingManager.rightSidePanel showAnimated:NO callback:nil];
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

-(NSArray*)mailsOnDesk{
    NSMutableArray* mails = [NSMutableArray array];
    for (id<ElementNodeProtocol> element in interactionsManager.visibleNodes){
        if ([element isKindOfClass:[EmailNode class]]){
            EmailModel* emailModel = (EmailModel*)[[Deps sharedInstance].coreDataManager.mainContext existingObjectWithID:((EmailNode*)element).emailId error:nil];
            if (emailModel){
                [mails addObject:emailModel];
            }
        }
    }
    return mails;
}


-(void) elementTouched:(id<ElementNodeProtocol>)element{
    
}


-(void)longTouchOnPoint:(CGPoint)point{
    FolderModel* folder = [foldersTable folderModelAtPoint:point];
    if (folder == nil){
        if (CGRectContainsPoint(drawingManager.fastArchiveZone.boundingBox, point)) {
            //folder = [delegate arch];   TODO
        }
    }
    
    if (folder != nil){
        EmailModel* email = [delegate lastEmailFromFolder:folder];
        if (email != nil){
            CGPoint popingPoint = CGPointZero;
            if (CGRectContainsPoint(drawingManager.fastArchiveZone.boundingBox, point)) {
                CGRect fastArchiveBoundingBox = drawingManager.fastArchiveZone.boundingBox;
                CGPoint point = CGPointMake(fastArchiveBoundingBox.origin.x + fastArchiveBoundingBox.size.width/2, fastArchiveBoundingBox.origin.y + fastArchiveBoundingBox.size.height/2);
                popingPoint = [DropZoneNode visualCenterFromRealCenter:point];
            }else{
                popingPoint = [foldersTable centerOfFolderAtPoint:point];
            }
            NSLog(@"%@",NSStringFromCGPoint(popingPoint));
            NSLog(@"%@",NSStringFromCGPoint(point));
            id<ElementNodeProtocol> node = [drawingManager.inboxStack addEmail:email onPoint:popingPoint];
            [self addChild:node z:3];//le poping point est pas bon
            [interactionsManager registerNode:node];
        }
    }
}



-(BOOL) element:(id<ElementNodeProtocol>)element droppedAt:(CGPoint)point{
    FolderModel* folder = [foldersTable folderModelAtPoint:point];
    if (folder != nil){
        if ([element isKindOfClass:[EmailNode class]]){
            EmailModel* emailModel = (EmailModel*)[[Deps sharedInstance].coreDataManager.mainContext existingObjectWithID:((EmailNode*)element).emailId error:nil];
            if (emailModel){
                [delegate moveEmail:emailModel toFolder:folder];
                [interactionsManager unregisterNode:element];
                [drawingManager scaleOut:[element visualNode]];
            }
        }
        return false;
    }else if (CGRectContainsPoint(drawingManager.fastArchiveZone.boundingBox, point)) {
        if ([element isKindOfClass:[EmailNode class]]){
            EmailModel* emailModel = (EmailModel*)[[Deps sharedInstance].coreDataManager.mainContext existingObjectWithID:((EmailNode*)element).emailId error:nil];
            if (emailModel){
                [delegate moveEmail:emailModel toFolder:[delegate archiveFolderForEmail:emailModel]];
                [interactionsManager unregisterNode:element];
                [drawingManager scaleOut:[element visualNode]];
            }          
        }
        return false;
    }
    return true;
}

-(void)cleanDesk{
    NSArray *visibleNodes = [NSArray arrayWithArray:interactionsManager.visibleNodes];
    for (id<ElementNodeProtocol> node in visibleNodes){
        [interactionsManager unregisterNode:node];
        [drawingManager scaleOut:[node visualNode]];
    }
    [self setPercentage:0 labelCount:-1];
}

-(void) tick: (ccTime) dt{
	[interactionsManager tick:dt];
}

@end
