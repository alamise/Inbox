//
//  BattlefieldModel.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/13/11.
//

#import <Foundation/Foundation.h>
#import "CTCoreAccount.h"

@interface BattlefieldModel : NSObject{
    NSString *email;
    NSString *password;
    BOOL endAsap;
    NSConditionLock* lock;
    NSMutableArray* wordsToSort;
    NSMutableDictionary* sortedWords;
    
}
    -(id)initWithEmail:(NSString*)email password:(NSString*)password;
    
    -(NSString*)getNextWord;
    -(void)sortedWord:(NSString*)word isGood:(BOOL)isGood;
    
    -(BOOL)isDone;
    -(void)end;
@end
