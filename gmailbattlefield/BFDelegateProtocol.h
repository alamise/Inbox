//
//  BattlefieldLayerDelegate.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/30/11.
//

#import <Foundation/Foundation.h>
@class EmailModel;
@protocol BFDelegateProtocol <NSObject>
    -(void)sortedEmail:(EmailModel*)word isGood:(BOOL)isGood;
@end
