#import <UIKit/UIKit.h>

@class Reachability;

@interface ErrorController : UIViewController{
    Reachability* internetReachable;
    BOOL isInternetReachable;
    
    IBOutlet UIView *connectionIsBackView;
    IBOutlet UIView *noConnectionView;
    IBOutlet UIView *errorView;
    IBOutlet UIView *loadingView;
    
    BOOL shouldRetry;
    void (^retryBlock)();
    
}
@property(nonatomic, copy) void(^retryBlock)();

- (IBAction)dismiss;
- (IBAction)editAccount;
- (id)initWithRetryBlock:(void(^)())retry;   
@end
