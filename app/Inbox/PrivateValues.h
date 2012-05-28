//
//  PrivateValues.h
//  Inbox
//
//  Created by Simon Watiau on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PrivateValues : NSObject{
    NSDictionary* values;
}
+(PrivateValues*)sharedInstance;

-(NSString*)flurryApiKey;

-(NSString*)quincyServer;

-(NSString*)myPassword;
@end
