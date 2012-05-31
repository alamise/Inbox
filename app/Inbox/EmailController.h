#import <UIKit/UIKit.h>
#import "EmailModel.h"

@interface EmailController : UIViewController{
    NSManagedObjectID* emailId;
    IBOutlet UIWebView* webView;

}
-(id)initWithEmail:(NSManagedObjectID*)emailId;
@end
