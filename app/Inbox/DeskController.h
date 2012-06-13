#import <UIKit/UIKit.h>
#import "DeskProtocol.h"
@class MBProgressHUD, DeskLayer, EAGLView, ModelsManager;

@interface DeskController : UIViewController<DeskProtocol> {
    ModelsManager *modelsManager;
    DeskLayer *layer;
    EAGLView *glView;
    int totalEmailsInThisSession;
    UIActivityIndicatorView *loadingIndicator;
}

@property(nonatomic,retain,readonly) ModelsManager *modelsManager;

- (void)cleanDesk;
- (void)setLoaderVisible:(BOOL)visible;
@end
