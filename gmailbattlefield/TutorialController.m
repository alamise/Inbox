//
//  TutorialController.m
//  gmailbattlefield
//
//  Created by Simon Watiau on 12/4/11.
//

#import "TutorialController.h"
#import "LoginController.h"
#define TUTORIAL_VIEW_WIDTH 540
#define TUTORIAL_VIEW_HEIGHT 540
@implementation TutorialController
@synthesize field;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        UIBarButtonItem *skipButton = [[UIBarButtonItem alloc] initWithTitle:@"Skip" style:UIBarButtonItemStylePlain target:self action:@selector(goToNextStep)];          
        self.navigationItem.rightBarButtonItem = skipButton;
        [skipButton release];
    }
    return self;
}

- (void)dealloc {
    self.field = nil;
    [pageControl release];
    [scrollView release];
    [tutorialViews release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

-(void)scrollViewDidEndDecelerating:(UIScrollView *)s{
    int page = s.contentOffset.x/TUTORIAL_VIEW_WIDTH;
    pageControl.currentPage=page;
}

-(IBAction)pageChanged{
    int page = pageControl.currentPage;
    [scrollView scrollRectToVisible:CGRectMake(page*TUTORIAL_VIEW_WIDTH, 0, TUTORIAL_VIEW_WIDTH, TUTORIAL_VIEW_HEIGHT) animated:YES];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    int currentX=0;
    [scrollView setContentSize:CGSizeMake([tutorialViews count]*TUTORIAL_VIEW_WIDTH, TUTORIAL_VIEW_HEIGHT)];
    for (UIView* view in tutorialViews){
        CGRect frame = view.frame;
        frame.origin=CGPointMake(currentX, 0);
        view.frame = frame;
        [scrollView addSubview:view];
        currentX+=view.frame.size.width;
    }
    pageControl.numberOfPages=[tutorialViews count];
}

- (void)viewDidUnload{
    [pageControl release];
    pageControl = nil;
    [scrollView release];
    scrollView = nil;
    [tutorialViews release];
    tutorialViews = nil;
    [super viewDidUnload];
}

-(IBAction)goToNextStep{
    LoginController* loginView = [[LoginController alloc] initWithNibName:@"LoginView" bundle:nil];
    loginView.field=self.field;
    [self.navigationController pushViewController:loginView animated:YES];
    [loginView release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft)||(interfaceOrientation==UIInterfaceOrientationLandscapeRight));
}


@end
