//
//  RootViewController.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/11/11.
//

#import <UIKit/UIKit.h>
#import "DeskProtocol.h"
@class  MBProgressHUD,GmailModel,DeskLayer,EAGLView;
@interface DeskController : UIViewController<DeskProtocol> {
    GmailModel* model;
    DeskLayer* layer;
    BOOL isLoading;
    EAGLView* glView;
    MBProgressHUD* loadingHud;
    BOOL isWaiting;
    BOOL isSyncing;
}
@property(readonly) GmailModel* model;
-(void)resetModel;
-(void)linkToModel;
-(void)unlinkToModel;
@end
