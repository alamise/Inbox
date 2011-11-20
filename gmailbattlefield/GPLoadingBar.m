//////////////////////////GAME PACK/////////////////////////////
//                                                            //
//  GPLoadingBar.m                                            //
//  GPLoadingBarExample                                       //
//                                                            //
//  Created by Techy on 6/17/11.                              //
//  Copyright 2011 Web-Geeks/Wrensation.                      //
//                                                            //
////////////////////////////////////////////////////////////////

#import "GPLoadingBar.h"

@implementation GPLoadingBar
@synthesize bar, inset, type, active, loadingProgress;

+(id) loadingBarWithBar:(NSString *)b inset:(NSString *)i mask:(NSString *)m {
    return [[[self alloc] initLoadingBarWithBar:b inset:i mask:m] autorelease];
}

-(id) initLoadingBarWithBar:(NSString *)b inset:(NSString *)i mask:(NSString *)m {
    if ((self = [super init])) {
        bar = [[NSString alloc] initWithString:b];
        inset = [[NSString alloc] initWithString:i];
        mask = [[NSString alloc] initWithString:m];
        spritesheet = NO;
        
        screenSize = [[CCDirector sharedDirector] winSize];
        
        screenMid = ccp(screenSize.width * 0.5f, screenSize.height * 0.5f);
        
        barSprite = [[CCSprite alloc] initWithFile:bar];
        barSprite.anchorPoint = ccp(0.5,0.5);
        barSprite.position = screenMid;
        
        insetSprite = [[CCSprite alloc] initWithFile:inset];
        insetSprite.anchorPoint = ccp(0.5,0.5);
        insetSprite.position = screenMid;
        [self addChild:insetSprite z:1];
        
        maskSprite = [[CCSprite alloc] initWithFile:mask];
        maskSprite.anchorPoint = ccp(1,0.5);
        maskSprite.position = ccp(((screenSize.width - barSprite.boundingBox.size.width) / 2), screenMid.y);
        
        renderMasked = [[CCRenderTexture alloc] initWithWidth:screenSize.width height:screenSize.height pixelFormat:kCCTexture2DPixelFormat_RGBA8888];
        [[renderMasked sprite] setBlendFunc: (ccBlendFunc) {GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA}];
        renderMasked.position = barSprite.position;
        renderMaskNegative = [[CCRenderTexture alloc] initWithWidth:screenSize.width height:screenSize.height pixelFormat:kCCTexture2DPixelFormat_RGBA8888];
        [[renderMaskNegative sprite] setBlendFunc: (ccBlendFunc) {GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA}];
        renderMaskNegative.position = barSprite.position;
        
        [maskSprite setBlendFunc: (ccBlendFunc) {GL_ZERO, GL_ONE_MINUS_SRC_ALPHA}];
        [maskSprite retain];
        
        [self clearRender];
        
        [self maskBar];
        
        [self addChild:renderMasked z:2];
    }
    return self;
}

+(id) loadingBarWithBarFrame:(NSString *)b insetFrame:(NSString *)i maskFrame:(NSString *)m {
    return [[[self alloc] initLoadingBarWithBarFrame:b insetFrame:i maskFrame:m] autorelease];
}
-(id) initLoadingBarWithBarFrame:(NSString *)b insetFrame:(NSString *)i maskFrame:(NSString *)m {
    if ((self = [super init])) {
        bar = [[NSString alloc] initWithString:b];
        inset = [[NSString alloc] initWithString:i];
        mask = [[NSString alloc] initWithString:m];
        spritesheet = YES;
        
		screenSize = [[CCDirector sharedDirector] winSize];
        
        screenMid = ccp(screenSize.width * 0.5f, screenSize.height * 0.5f);
        
        barSprite = [[CCSprite alloc] initWithSpriteFrameName:bar];
        barSprite.anchorPoint = ccp(0.5,0.5);
        barSprite.position = screenMid;
        
        insetSprite = [[CCSprite alloc] initWithSpriteFrameName:inset];
        insetSprite.anchorPoint = ccp(0.5,0.5);
        insetSprite.position = screenMid;
        [self addChild:insetSprite z:1];
        
        maskSprite = [[CCSprite alloc] initWithSpriteFrameName:mask];
        maskSprite.anchorPoint = ccp(1,0.5);
        maskSprite.position = ccp(((screenSize.width - barSprite.boundingBox.size.width) / 2), screenMid.y);
        
        renderMasked = [[CCRenderTexture alloc] initWithWidth:screenSize.width height:screenSize.height pixelFormat:kCCTexture2DPixelFormat_RGBA8888];
        [[renderMasked sprite] setBlendFunc: (ccBlendFunc) {GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA}];
        renderMasked.position = barSprite.position;
        renderMaskNegative = [[CCRenderTexture alloc] initWithWidth:screenSize.width height:screenSize.height pixelFormat:kCCTexture2DPixelFormat_RGBA8888];
        [[renderMaskNegative sprite] setBlendFunc: (ccBlendFunc) {GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA}];
        renderMaskNegative.position = barSprite.position;
        
        [maskSprite setBlendFunc: (ccBlendFunc) {GL_ZERO, GL_ONE_MINUS_SRC_ALPHA}];
        [maskSprite retain];
        
        [self clearRender];
        
        [self maskBar];
        
        [self addChild:renderMasked z:2];
    }
    return self;
}
-(void) clearRender {
    [renderMasked beginWithClear:0.0f g:0.0f b:0.0f a:0.0f];
    
    [barSprite visit];
    
    [renderMasked end];
    
    [renderMaskNegative beginWithClear:0.0f g:0.0f b:0.0f a:0.0f];
    
    [barSprite visit];
    
    [renderMaskNegative end];
}
-(void) maskBar{
    [renderMaskNegative begin];
    
    glColorMask(0.0f, 0.0f, 0.0f, 1.0f);
    
    [maskSprite visit];
    
    glColorMask(1.0f, 1.0f, 1.0f, 1.0f);
    
    [renderMaskNegative end];
    
    masked = renderMaskNegative.sprite;
    masked.position = screenMid;
    
    [masked setBlendFunc: (ccBlendFunc) { GL_ZERO, GL_ONE_MINUS_SRC_ALPHA }];
    [masked retain];
    
    [renderMasked begin];
    
    glColorMask(0.0f, 0.0f, 0.0f, 1.0f);
    
    [masked visit];
    
    glColorMask(1.0f, 1.0f, 1.0f, 1.0f);
    
    [renderMasked end];
}
-(void) setLoadingProgress:(float)lp {
    loadingProgress = lp;
    [self drawLoadingBar];
}
-(void) drawLoadingBar {
    maskSprite.position = ccp(((screenSize.width - barSprite.boundingBox.size.width) / 2) +(loadingProgress / 100 * barSprite.boundingBox.size.width), screenMid.y);
    [self clearRender];
    [self maskBar];
}
-(void)dealloc{
    [masked release];
    [renderMasked release];
    [renderMaskNegative release];
    [maskSprite release];
    [barSprite release];
    [insetSprite release];
    [mask release];
    [bar release];
    [inset release];
    [super dealloc];
}

@end
