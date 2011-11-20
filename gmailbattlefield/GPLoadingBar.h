//////////////////////////GAME PACK/////////////////////////////
//                                                            //
//  GPLoadingBar.h                                            //
//  GPLoadingBarExample                                       //
//                                                            //
//  Created by Techy on 6/17/11.                              //
//  Copyright 2011 Web-Geeks/Wrensation.                      //
//                                                            //
////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import "cocos2d.h"

typedef enum{
	kBarRounded,
	kBarRectangle,
} kBarTypes;

@interface GPLoadingBar : CCLayer {
    NSString *bar, *inset, *mask;
    CCSprite *barSprite, *maskSprite, *insetSprite, *masked;
    CCRenderTexture *renderMasked, *renderMaskNegative;
    kBarTypes type;
    float loadingProgress;
    BOOL active, spritesheet;
    CGPoint screenMid;
    CGSize screenSize;
}
@property(nonatomic, retain ,readonly)	NSString *bar, *inset;
@property(nonatomic) float loadingProgress;
@property kBarTypes type;
@property BOOL active;

+(id) loadingBarWithBar:(NSString *)b inset:(NSString *)i mask:(NSString *)m;
-(id) initLoadingBarWithBar:(NSString *)b inset:(NSString *)i mask:(NSString *)m;
+(id) loadingBarWithBarFrame:(NSString *)b insetFrame:(NSString *)i maskFrame:(NSString *)m;
-(id) initLoadingBarWithBarFrame:(NSString *)b insetFrame:(NSString *)i maskFrame:(NSString *)m;

-(void) setLoadingProgress:(float)lv;
-(void) clearRender;
-(void) maskBar;
-(void) drawLoadingBar;

@end
