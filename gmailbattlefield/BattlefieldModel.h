//
//  BattlefieldModel.h
//  gmailbattlefield
//
//  Created by Simon Watiau on 11/13/11.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CTCoreAccount.h"
#import "BFModelProtocol.h"
@interface BattlefieldModel : NSObject{
    NSString *email;
    NSString *password;
    BOOL shouldEnd; // Stop the thread asap
    NSLock* threadLock; // used to wait for the processing thread
    NSMutableArray* wordsToSort;
    NSMutableDictionary* sortedWords;
    id<BFModelProtocol> delegate;
    
    NSFetchedResultsController *fetchedResultsController;
    NSManagedObjectContext *managedObjectContext;
}

@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@property(nonatomic,retain) id<BFModelProtocol> delegate;
-(id)initWithEmail:(NSString*)email password:(NSString*)password;
// Return the next word to sort or nil if there is no more word
-(NSString*)getNextWord;
// To call when a word is sorted
-(void)sortedWord:(NSString*)word isGood:(BOOL)isGood;
-(BOOL)isDone;
// Wait for the processing thread to finish and return
-(void)end;
-(void)startProcessing;
@end
