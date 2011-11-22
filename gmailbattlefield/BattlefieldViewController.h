//
//  RootViewController.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/11/11.
//

#import <UIKit/UIKit.h>
#import "BattlefieldLayer.h"
@interface BattlefieldViewController : UIViewController {
    BattlefieldLayer* layer;
}
@property(nonatomic,retain) BattlefieldLayer* layer;
@end
