//
//  ErrorController.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 12/26/11.
//

#import <UIKit/UIKit.h>

@class Reachability, BattlefieldController;
@interface ErrorController : UIViewController{
    Reachability* internetReachable;
    BOOL isInternetReachable;
    BOOL isHostReachable;
    BOOL isWifi;
    IBOutlet UIView *connectionIsBackView;
    IBOutlet UIView *noConnectionView;
    IBOutlet UIView *errorView;
    IBOutlet UIView *loadingView;
    BattlefieldController* field;
}
@property(nonatomic,retain) BattlefieldController* field;

    - (void) checkNetworkStatus:(NSNotification *)notice;
    -(IBAction)dismiss;
    -(IBAction)editAccount;
@end
