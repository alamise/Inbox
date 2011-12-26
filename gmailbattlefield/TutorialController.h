//
//  TutorialController.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 12/4/11.
//

#import <UIKit/UIKit.h>
@class BattlefieldController;
@interface TutorialController : UIViewController<UIScrollViewDelegate> {

    IBOutlet UIScrollView *scrollView;
    IBOutlet UIPageControl *pageControl;
    BattlefieldController* field;
    IBOutletCollection(UIView) NSArray *tutorialViews;
}
@property(nonatomic,retain) BattlefieldController* field;
-(IBAction)goToNextStep;
-(IBAction)pageChanged;
@end
