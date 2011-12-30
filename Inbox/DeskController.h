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
    NSArray* folders;
}
@property(readonly) GmailModel* model;
-(void)reload;
@end
