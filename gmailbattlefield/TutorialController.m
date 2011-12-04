//
//  TutorialController.m
//  gmailbattlefield
//
//  Created by Simon Watiau on 12/4/11.
//

#import "TutorialController.h"
#import "LoginController.h"
@implementation TutorialController



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        UIBarButtonItem *skipButton = [[UIBarButtonItem alloc] initWithTitle:@"Skip" style:UIBarButtonItemStylePlain target:self action:@selector(goToNextStep)];          
        self.navigationItem.rightBarButtonItem = skipButton;
        [skipButton release];
    }
    return self;
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad{
    [super viewDidLoad];
}

- (void)viewDidUnload{
    [pageControl release];
    pageControl = nil;
    [scrollView release];
    scrollView = nil;
    [super viewDidUnload];
}

-(void)goToNextStep{
    LoginController* loginView = [[LoginController alloc] init];
    [self.navigationController pushViewController:loginView animated:YES];
    [loginView release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [pageControl release];
    [scrollView release];
    [super dealloc];
}
@end
