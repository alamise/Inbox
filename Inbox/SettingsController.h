//
//  SettingsController.h
//  Inbox
//
//  Created by Simon Watiau on 12/29/11.
//

#import <UIKit/UIKit.h>

@interface SettingsController : UIViewController{
    
    IBOutlet UILabel *inboxCountLabel;
    IBOutlet UILabel *inboxCountValue;

    IBOutlet UILabel *lastSyncValue;
    IBOutlet UILabel *lastSyncLabel;
    IBOutlet UILabel *accountValue;
    IBOutlet UILabel *accountLabel;
}
- (IBAction)sync:(id)sender;
- (IBAction)editAccount:(id)sender;

@end
