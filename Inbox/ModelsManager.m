//
//  ModelsManager.m
//  Inbox
//
//  Created by Simon Watiau on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ModelsManager.h"
#import "AppDelegate.h"
#import "models.h"

@implementation ModelsManager



-(id)init{
    if (self = [super init]){
        
    }
    return self;
}


-(void)dealloc{
    for (EmailAccount* account in emailsAccount){
        [account stopActivitiesAsap];
    }
    [emailsAccount release];
    [super dealloc];
}

-(void)refreshEmailAccountsPool{
    
    for (EmailAccount* account in emailsAccount){
        [account stopActivitiesAsap];
    }
    [emailsAccount removeAllObjects];
    
    NSManagedObjectContext* context = [[(AppDelegate*)[UIApplication sharedApplication].delegate newManagedObjectContext] retain];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[EmailAccountModel entityName] inManagedObjectContext:context];
    request.entity = entity;
    [request setPropertiesToFetch:[entity properties]];
    NSError* fetchError;
    NSArray* emailsModels = [context executeFetchRequest:request error:&fetchError];
    if (fetchError){
        // TODO
    }
    
    for (EmailAccountModel* model in emailsModels){
        EmailAccount* account = [[EmailAccount alloc] initWithAccountModel:model];
        [emailsAccount addObject:account];
        [account release];
    }
    [context release];
    [request release];
}


@end
