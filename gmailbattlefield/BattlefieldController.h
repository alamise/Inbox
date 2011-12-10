//
//  RootViewController.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/11/11.
//

#import <UIKit/UIKit.h>
#import "BattlefieldLayer.h"
#import "BFModelProtocol.h"
#import "BFDelegateProtocol.h"
#import "BattlefieldModel.h"
@class  MBProgressHUD;
@interface BattlefieldController : UIViewController<BFDelegateProtocol,BFModelProtocol> {
    BattlefieldModel* model;
    BattlefieldLayer* layer;
    BOOL isLoading;
    EAGLView* glView;
    MBProgressHUD* loadingHud;
}
@end
