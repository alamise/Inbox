#import "cocos2d.h"
#import "Box2D.h"
#import "DeskProtocol.h"
#import "DropZoneNode.h"
#import "SWTableView.h"
#import "GLES-Render.h"
#import "ProgressIndicator.h"
#import "InboxStack.h"
#import "InteractionsManagerDelegateProtocol.h"
#import "DrawingManagerDelegateProtocol.h"
#import "FoldersTable.h"

@class EmailNode, EmailModel, SWTableView,InteractionsManager,DrawingManager;

@interface DeskLayer : CCLayer<DrawingManagerDelegateProtocol,InteractionsManagerDelegateProtocol>{
    id<DeskProtocol> delegate;
    InteractionsManager* interactionsManager;
    DrawingManager* drawingManager;
    
    FoldersTable* foldersTable;
}

-(id) initWithDelegate:(id<DeskProtocol>)d;
-(void) putEmail:(EmailModel*)model;

-(void) cleanDesk;
-(int) elementsOnTheDesk;
-(void) refresh;

-(NSArray*)mailsOnDesk;
-(void)setPercentage:(float)percentage labelCount:(int)count;
-(void)showFolders:(NSArray*)folders;
@end

