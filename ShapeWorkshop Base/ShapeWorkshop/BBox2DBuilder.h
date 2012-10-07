//
//  BBox2DBuilder.h
//  Introduction to Physics
//
//  Created by Ben Smiley-Andrews on 23/05/2012.
//  Copyright (c) 2012 Deluge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLevel.h"
#import "Box2D.h"
#import "GLES-Render.h"


@interface BBox2DBuilder : NSObject {
    b2World * _world;
    GLESDebugDraw * _debugDraw;
    __weak BLevel * _level;
    BOOL _debug;
}

@property (nonatomic, readonly) b2World * world;
@property (nonatomic, readonly) BOOL debug;

+(id) box2DBuilderWithLevel: (BLevel *) level withDebug: (BOOL) debug;

-(void) addSpritesToLayer: (CCLayer *) layer;

-(float) stwAngle: (float) angle;
-(float) wtsAngle: (float) angle;
-(float) stwFloat: (float) value;
-(float) wtsFloat: (float) value;
-(b2Vec2) stwVector: (b2Vec2) vector;
-(b2Vec2) wtsVector: (b2Vec2) vector;
-(void) update: (ccTime) dt;
-(void) draw;
-(void) setScaleFromLevel: (CCLayer *) layer;
-(void) setScale: (CCLayer *) layer withScale: (float) scale withCenter: (CGPoint) scaleCenter;
+(b2Vec2) toVec2: (NSArray *) vector;
-(void) orderByZPosition: (CCLayer *) layer ;

/*
 * A helper method to make it easier to add a sprite sheet
 */
+(void) setSpriteSheet: (CCLayer *) layer withSpriteSheet:(NSString *) spriteSheet withPackFile: (NSString*) packFile;
@end
