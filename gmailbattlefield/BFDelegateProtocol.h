//
//  BattlefieldLayerDelegate.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/30/11.
//

#import <Foundation/Foundation.h>
#import "BattlefieldModel.h"
@class EmailModel;
@protocol BFDelegateProtocol <NSObject>
    -(void)email:(EmailModel*)email sortedTo:(folderType)folder;
    -(void)emailTouched:(EmailModel*)email;
@end
