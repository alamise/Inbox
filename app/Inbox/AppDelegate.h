#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "Logger.h"
#import "BWQuincyManager.h"
#import "CoreDataManager.h"
@class BackgroundThread;

@interface AppDelegate : NSObject <UIApplicationDelegate,BWQuincyManagerDelegate> {
	UIWindow *window;
    UINavigationController* navigationController;
}
@property (nonatomic, retain,readwrite) UIWindow *window;
+ (AppDelegate*)sharedInstance;
@end
