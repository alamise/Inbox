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

#import "InboxEmptyController.h"
#import "LoginController.h"
#import "GANTracker.h"

@implementation InboxEmptyController
@synthesize  actionOnDismiss;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        shouldExecActionOnDismiss = NO;
    }
    return self;
}

-(void)dealloc{
    self.actionOnDismiss = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad{
    [super viewDidLoad];
}

- (void)viewDidUnload{
    [super viewDidUnload];
}

-(void)viewDidDisappear:(BOOL)animated{
    if (shouldExecActionOnDismiss){
        [self.actionOnDismiss start];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[GANTracker sharedTracker] trackPageview:@"/inbox_empty" withError:nil];
}

- (IBAction)onRefresh {
    [[GANTracker sharedTracker] trackPageview:@"/inbox_empty/refresh" withError:nil];
    shouldExecActionOnDismiss = YES;
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)onEditAccount {
    [[GANTracker sharedTracker] trackPageview:@"/inbox_empty/edit_account" withError:nil];
    LoginController* loginCtr = [[[LoginController alloc] initWithNibName:@"LoginView" bundle:nil] autorelease];
    loginCtr.actionOnDismiss = self.actionOnDismiss;
    [self.navigationController pushViewController:loginCtr animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

@end
