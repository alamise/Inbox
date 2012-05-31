#import <Foundation/Foundation.h>

@interface PrivateValues : NSObject{
    NSDictionary* values;
}
+(PrivateValues*)sharedInstance;

-(NSString*)flurryApiKey;

-(NSString*)quincyServer;

-(NSString*)myPassword;
@end
