#import "Deps.h"
#import "ThreadsManager.h"
#import "CoreDataManager.h"
#import "SynchroManager.h"
#import "DeskController.h"
#import "ActivityManager.h"

static Deps* instance;

@interface Deps ()
@property(nonatomic, retain, readwrite) CoreDataManager *coreDataManager;
@property(nonatomic, retain, readwrite) ThreadsManager *threadsManager;
@property(nonatomic, retain, readwrite) SynchroManager *synchroManager;
@property(nonatomic, retain, readwrite) DeskController *deskController;
@property(nonatomic, retain, readwrite) ActivityManager *activityManager;
@end

@implementation Deps

@synthesize coreDataManager;
@synthesize threadsManager;
@synthesize synchroManager;
@synthesize deskController;
@synthesize activityManager;

+ (Deps*) sharedInstance{
    if (!instance){
        instance = [[Deps alloc] init];
        [instance.coreDataManager postInit];
    }
    return instance;
}


- (void) dealloc {
    self.coreDataManager = nil;
    self.threadsManager = nil;
    self.synchroManager = nil;
    self.activityManager = nil;
    [super dealloc];
}

- (id) init {
    if (self = [super init]){
        self.threadsManager = [[[ThreadsManager alloc] init] autorelease];
        [self.threadsManager.thread start];
        self.activityManager = [[[ActivityManager alloc] init] autorelease];
        self.coreDataManager = [[[CoreDataManager alloc] init] autorelease];
        self.deskController = [[[DeskController alloc] init] autorelease];
        self.synchroManager = [[[SynchroManager alloc] init] autorelease];
    }
    return self;
}

@end
