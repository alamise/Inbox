#import <UIKit/UIKit.h>
#import "DeskController.h"

@interface InboxEmptyController : UIViewController{
    NSInvocationOperation* actionOnDismiss;
    BOOL shouldExecActionOnDismiss;
}
@property(nonatomic,retain) NSInvocationOperation* actionOnDismiss;
- (IBAction)onRefresh;
- (IBAction)onEditAccount;
@end
