#import "PrivateValues.h"
static PrivateValues* instance;
@implementation PrivateValues

+(PrivateValues*)sharedInstance{
    if (!instance){
        instance = [[PrivateValues alloc] init];
    }
    return instance;
}

-(id)init{
    if (self = [super init]){
        values = [[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"private" ofType:@"plist"]] retain];
    }
    return self;
}


-(NSString*)flurryApiKey{
    return [values objectForKey:@"flurryApiKey"];
}

-(NSString*)quincyServer{
    return [values objectForKey:@"quincyServer"];
}

-(NSString*)myPassword{
    return [values objectForKey:@"myPassword"];
}

@end
