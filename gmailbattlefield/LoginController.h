//
//  LoginController.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/27/11.
//

#import <UIKit/UIKit.h>
@interface LoginController : UIViewController {
    IBOutlet UITextField *emailField;
    IBOutlet UITextField *passwordField;
    IBOutlet UIButton *submitButton;
}

- (IBAction)onLogin:(id)sender;

@end
