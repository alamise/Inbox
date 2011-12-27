//
//  TutorialController.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 12/4/11.
//

#import <UIKit/UIKit.h>
@class DeskController;
@interface TutorialController : UIViewController<UIScrollViewDelegate> {

    IBOutlet UIScrollView *scrollView;
    IBOutlet UIPageControl *pageControl;
    DeskController* field;
    IBOutletCollection(UIView) NSArray *tutorialViews;
}
@property(nonatomic,retain) DeskController* field;
-(IBAction)goToNextStep;
-(IBAction)pageChanged;
@end
