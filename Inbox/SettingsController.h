//
//  SettingsController.h
//  Inbox
//
//  Created by Simon Watiau on 12/29/11.
//

#import <UIKit/UIKit.h>

@interface SettingsController : UIViewController<UITableViewDelegate,UITableViewDataSource>{
    
    IBOutlet UILabel *inboxCountLabel;
    IBOutlet UITableView *optionsTable;
}

@end
