#import "NSArray+CoreData.h"
#import <CoreData/CoreData.h>

@implementation NSArray (CoreData)

- (NSArray *)ArrayOfManagedIds {
    NSMutableArray* result = [NSMutableArray array];
    for ( NSObject* element in self ) {
        if ( [element isKindOfClass:[NSManagedObject class]] ) {
            [result addObject:((NSManagedObject *)element).objectID];
        }
    }
    return result;
}

@end
