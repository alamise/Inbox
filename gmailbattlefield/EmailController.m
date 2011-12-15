//
//  EmailController.m
//  gmailbattlefield
//
//  Created by Simon Watiau on 12/14/11.
//

#import "EmailController.h"

@implementation EmailController

-(id)initWithEmailModel:(EmailModel*)model{
    if (self = [super initWithNibName:@"EmailView" bundle:nil]){
        self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)];
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad{
    [super viewDidLoad];
}

- (void)viewDidUnload{
    [super viewDidUnload];
    // e.g. self.myOutlet = nil;
}

-(void)close{
    [self dismissModalViewControllerAnimated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft)||(interfaceOrientation==UIInterfaceOrientationLandscapeRight));
}

@end
