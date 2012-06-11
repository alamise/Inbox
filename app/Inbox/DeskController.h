#import <UIKit/UIKit.h>
#import "DeskProtocol.h"
@class MBProgressHUD, DeskLayer, EAGLView, ModelsManager;

@interface DeskController : UIViewController<DeskProtocol> {
    ModelsManager *modelsManager;
    DeskLayer *layer;
    EAGLView *glView;
    MBProgressHUD *loadingHud;
    int totalEmailsInThisSession;
}

@property(nonatomic,retain,readonly) ModelsManager *modelsManager;

@end
