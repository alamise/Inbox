//
//  EmailController.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 12/14/11.
//

#import <UIKit/UIKit.h>
#import "EmailModel.h"

@interface EmailController : UIViewController{
    EmailModel* emailModel;
    IBOutlet UIWebView* webView;

}
-(id)initWithEmailModel:(EmailModel*)model;
@end
