//
//  BattlefieldLayerDelegate.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BFDelegateProtocol <NSObject>
    -(void)sortedWord:(NSString*)word isGood:(BOOL)isGood;
@end
