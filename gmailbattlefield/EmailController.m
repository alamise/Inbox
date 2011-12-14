//
//  EmailController.m
//  gmailbattlefield
//
//  Created by Simon Watiau on 12/14/11.
//

#import "EmailController.h"

@implementation EmailController

-(id)initWithEmailModel:(EmailModel*)model{
    if (self = [super init]){
    
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return YES;
}

@end
