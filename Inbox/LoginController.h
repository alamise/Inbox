//
//  LoginController.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/27/11.
//

#import <UIKit/UIKit.h>
@class DeskController;
@interface LoginController : UIViewController {
    IBOutlet UITextField *emailField;
    IBOutlet UITextField *passwordField;
    IBOutlet UIButton *submitButton;
    DeskController* desk;
}
@property(nonatomic,retain) DeskController* desk;
- (IBAction)onLogin:(id)sender;
-(void)linkToModel;
-(void)unlinkToModel;
@end
