#import "Reader.h"
#import "Deps.h"

static Reader* instance;
@implementation Reader

+(void)setInstance:(Reader*)ins{
    [instance autorelease];
    instance = [ins retain];
}

+(Reader*)getInstance{
    return instance;
}

+(Reader*)sharedInstance{
    return nil;
}

-(NSManagedObjectContext*)sharedContext{
    return [[[Deps sharedInstance] coreDataManager] mainContext];
}

@end
