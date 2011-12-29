//
//  SettingsController.m
//  Inbox
//
//  Created by Simon Watiau on 12/29/11.
//

#import "SettingsController.h"

@implementation SettingsController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)dealloc {
    [inboxCountLabel release];
    [optionsTable release];
    [super dealloc];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString* identifier = @"ident";
    UITableViewCell* cell  = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell){
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
    }
    
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text=@"copy";
            cell.detailTextLabel.text=@"send or get emails";
            break;
        case 1:
            cell.textLabel.text=@"Account";
            cell.detailTextLabel.text=@"Change your Gmail account";
            break;
        case 2:
            
            break;
        default:
            break;
    }
    return cell;
}



#pragma mark - View lifecycle

- (void)viewDidLoad{
    [super viewDidLoad];
}

- (void)viewDidUnload{
    [inboxCountLabel release];
    inboxCountLabel = nil;
    [optionsTable release];
    optionsTable = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
	return YES;
}

@end
