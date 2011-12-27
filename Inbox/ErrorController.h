//
//  ErrorController.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 12/26/11.
//

#import <UIKit/UIKit.h>

@class Reachability, DeskController;
@interface ErrorController : UIViewController{
    Reachability* internetReachable;
    BOOL isInternetReachable;
    BOOL isHostReachable;
    BOOL isWifi;
    IBOutlet UIView *connectionIsBackView;
    IBOutlet UIView *noConnectionView;
    IBOutlet UIView *errorView;
    IBOutlet UIView *loadingView;
    DeskController* field;
}
@property(nonatomic,retain) DeskController* field;

    - (void) checkNetworkStatus:(NSNotification *)notice;
    -(IBAction)dismiss;
    -(IBAction)editAccount;
@end
