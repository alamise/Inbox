#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "AppDelegate.h"

@interface Reader : NSObject{
    NSManagedObjectContext* coreDataContext;
}
+(void)setInstance:(Reader*)ins;
+(Reader*)getInstance;
-(NSManagedObjectContext*)sharedContext;
@end
