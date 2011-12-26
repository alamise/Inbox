//
//  LoginController.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/27/11.
//

#import <UIKit/UIKit.h>
@class BattlefieldController;
@interface LoginController : UIViewController {
    IBOutlet UITextField *emailField;
    IBOutlet UITextField *passwordField;
    IBOutlet UIButton *submitButton;
    BattlefieldController* field;
}
@property(nonatomic,retain) BattlefieldController* field;
- (IBAction)onLogin:(id)sender;

@end
