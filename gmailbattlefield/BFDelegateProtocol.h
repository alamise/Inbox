//
//  BattlefieldLayerDelegate.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/30/11.
//

#import <Foundation/Foundation.h>

@protocol BFDelegateProtocol <NSObject>
    -(void)sortedWord:(NSString*)word isGood:(BOOL)isGood;
@end
