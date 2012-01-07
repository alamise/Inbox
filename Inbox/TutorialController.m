/*
 *
 * Copyright (c) 2012 Simon Watiau.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

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
    loginView.desk=self.field;
    [self.navigationController pushViewController:loginView animated:YES];
    [loginView release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft)||(interfaceOrientation==UIInterfaceOrientationLandscapeRight));
}


@end
