#import <UIKit/UIKit.h>

@class LoginModel;
@class DeskController;

@interface LoginController : UIViewController {
    IBOutlet UITextField *emailField;
    IBOutlet UITextField *passwordField;
    IBOutlet UIButton *submitButton;
    BOOL shouldExecActionOnDismiss;
    LoginModel* model;
}
- (IBAction)onLogin:(id)sender;
@end
