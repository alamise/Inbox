//
//  RootViewController.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/11/11.
//

#import <UIKit/UIKit.h>
#import "BattlefieldLayer.h"
#import "BFDelegateProtocol.h"
#import "BattlefieldModel.h"
@interface BattlefieldController : UIViewController<BFDelegateProtocol> {
    BattlefieldModel* model;
    BattlefieldLayer* layer;
    BOOL isLoading;
    EAGLView* glView;
}
@property(nonatomic,retain) BattlefieldLayer* layer;
@end
