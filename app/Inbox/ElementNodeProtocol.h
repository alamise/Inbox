#import <Foundation/Foundation.h>
@class CCNode;
@protocol ElementNodeProtocol <NSObject>
    -(CCNode*) visualNode;
    -(void)scaleOut;
@end
