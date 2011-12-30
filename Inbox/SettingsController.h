//
//  SettingsController.h
//  Inbox
//
//  Created by Simon Watiau on 12/29/11.
//

#import <UIKit/UIKit.h>
#import "GmailModelProtocol.h"
@class DeskController;
@class MBProgressHUD;

@interface SettingsController : UIViewController<GmailModelProtocol>{
    
    IBOutlet UILabel *inboxCountLabel;
    IBOutlet UILabel *inboxCountValue;
    IBOutlet UILabel *lastSyncValue;
    IBOutlet UILabel *lastSyncLabel;
    IBOutlet UILabel *accountValue;
    IBOutlet UILabel *accountLabel;
    DeskController* desk;
    MBProgressHUD* hud;
}
@property(nonatomic,retain) DeskController* desk;
- (IBAction)sync:(id)sender;
- (IBAction)editAccount:(id)sender;

@end
