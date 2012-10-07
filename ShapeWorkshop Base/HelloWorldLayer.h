//
//  HelloWorldLayer.h
//  ShapeWorkshop Base
//
//  Created by Ben Smiley-Andrews on 28/05/2012.
//  Copyright Deluge 2012. All rights reserved.
//


#import <GameKit/GameKit.h>

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"

#import "BBox2DBuilder.h"
#import "BLevel.h"
#import "MyContactListener.h"


// HelloWorldLayer
@interface HelloWorldLayer : CCLayer {
    
    BBox2DBuilder * _builder;
    BLevel * _level;
    BElement * _ball;
    BOOL _runPhysics;
    b2World * _world;
    
    // Pointer to a hole
    BElement * _hole;
    BElement * _fan;    
    b2Vec2 _startPosition;
    
    b2Vec2 _ballForce;
     
    b2ContactListener * _contactListener;

    NSArray * _ballAnimationFrames;
    
    CCMenu * _menu;
    CCMenuItemFont * _button;
}

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;
-(void) startContact: (BElement *) elmA withElmB: (BElement *) elmB; 
-(void) endContact: (BElement *) elmA withElmB: (BElement *) elmB; 

@end
