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
@class EmailModel;
@interface BattlefieldModel : NSObject{
    NSString *email;
    NSString *password;
    BOOL shouldEnd; // Stop the thread asap
    NSLock* threadLock; // used to wait for the processing thread
    NSMutableArray* emailsToBeSorted;
    NSMutableDictionary* sortedEmails;
    id<BFModelProtocol> delegate;
    
    NSFetchedResultsController *fetchedResultsController;
    NSManagedObjectContext *managedObjectContext;
}

@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@property(nonatomic,retain) id<BFModelProtocol> delegate;
-(id)initWithAccount:(NSString*)email password:(NSString*)password;
// Return the next word to sort or nil if there is no more word
-(EmailModel*)getNextEmail;
// To call when a word is sorted
-(void)sortedEmail:(EmailModel*)model isGood:(BOOL)isGood;
-(BOOL)isDone;
// Wait for the processing thread to finish and return
-(void)end;
-(void)startProcessing;
@end
