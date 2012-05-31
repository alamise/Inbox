#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "DrawingManagerDelegateProtocol.h"

@class InboxStack, ProgressIndicator,ContextualRightSidePanel,DropZoneNode;

@interface DrawingManager : NSObject{
    CCLayer* layer;
    b2World* world;
    InboxStack* inboxStack;
    ProgressIndicator* progressIndicator;
    ContextualRightSidePanel* rightSidePanel;
    id<DrawingManagerDelegateProtocol> delegate;
    DropZoneNode* fastArchiveZone;
}
@property(readonly) InboxStack* inboxStack;
@property(readonly) ProgressIndicator* progressIndicator;
@property(readonly) ContextualRightSidePanel* rightSidePanel;
@property(readonly) DropZoneNode* fastArchiveZone;

-(id) initWithDelegate:(id<DrawingManagerDelegateProtocol>)d;
-(void) removeChildAndBody:(CCNode*)node;
-(void)scaleOut:(CCNode*)node;
-(void) refresh;

@end
