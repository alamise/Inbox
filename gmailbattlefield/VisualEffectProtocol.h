//
//  ScaleEffectProtocol.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 12/17/11.
//

#import <Foundation/Foundation.h>


@protocol VisualEffectProtocol <NSObject>
    // Set the next step in the animation
    -(void)setNextStep;
    // Should the object be removed
    -(BOOL)shouldBeRemoved;
@end
