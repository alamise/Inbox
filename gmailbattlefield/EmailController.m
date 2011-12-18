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
    
        emailModel = [model retain];
    }
    return self;
}
-(void)dealloc{
    [webView release];
    [emailModel release];
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad{
    [super viewDidLoad];
    NSLog(@"%@",emailModel.htmlBody);
    [webView loadHTMLString:emailModel.htmlBody baseURL:nil];
}

- (void)viewDidUnload{
    [super viewDidUnload];
    [webView release];
    webView = nil;
}

-(void)close{
    [self dismissModalViewControllerAnimated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft)||(interfaceOrientation==UIInterfaceOrientationLandscapeRight));
}

@end
