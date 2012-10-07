//
//  BBox2DBuilder.m
//  Introduction to Physics
//
//  Created by Ben Smiley-Andrews on 23/05/2012.
//  Copyright (c) 2012 Deluge. All rights reserved.
//

#import "BBox2DBuilder.h"

@implementation BBox2DBuilder

@synthesize world = _world;
@synthesize debug = _debug;

-(id) init {
    if((self=[super init])) {

    
    }
    return self;
}

// Create a new Box2D simulation by loading a level
+(id) box2DBuilderWithLevel:(BLevel *) level withDebug: (BOOL) debug {
    return [[self alloc] initWithLevel:level withDebug:debug];
}

// Add all the registered sprites to the layer. This 
// is done as an extra step to give more control if 
// this isn't the desired behavour
-(void) addSpritesToLayer: (CCLayer *) layer {
    
    // Loop over the elements and use the sprite link
    // to get the CCSprite to be added to the layer
    if(_level.elements != Nil) {
        for(BElement * e in _level.elements) {
            if(e.spriteLink != Nil) {
                if(![layer.children containsObject:e.spriteLink]) {
                    [layer addChild:e.spriteLink];
                }
            }
        }
    }
}

// A convenience method to add a sprite sheet to the level. Just provide the name of the sprite 
// sheet and the name of the packing file and the sprite sheet will be added to the layer as
// a batch node and all sprites contained will be made available
+(void) setSpriteSheet: (CCLayer *) layer withSpriteSheet:(NSString *) spriteSheet withPackFile: (NSString*) packFile {
    // Set the pixel format to 8888
    [CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA8888];
    // Create a new batch node - this holds the sprite sheet and is very fast
    CCSpriteBatchNode *spritesBgNode;
    // Load the sheet into the node.
    spritesBgNode = [CCSpriteBatchNode batchNodeWithFile:spriteSheet]; 
    // Add the sprite to the layer
    [layer addChild:spritesBgNode];
    
    // Add the pack file. This file tells Cocos2D how to unpack the sprite file
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:packFile];

}

// Set the layer scale to match the scale defined in the level object
-(void) setScaleFromLevel: (CCLayer *) layer {
    assert(_level.scale > 0);
    
    [self setScale: layer withScale: 1/(_level.scale)  withCenter:ccp(0,0)];    
}

// Zoom the layer in or our to a particular scale
-(void) setScale: (CCLayer *) layer withScale: (float) scale withCenter: (CGPoint) scaleCenter{
    // scaleCenter is the point to zoom to.. 
    // If you are doing a pinch zoom, this should be the center of your pinch.
    
    CGSize s = [[CCDirector sharedDirector] winSize];
    
    // This is because the zoom zooms into the centre of the screen 
    // to move the screen centre to the point we wan to zoom in on
    // we need to move apply this offset
    float screenCentreX = -s.width/2;
    float screenCentreY = -s.height/2;
    
    // Get the original center point.
    CGPoint oldCenterPoint = ccp((scaleCenter.x + screenCentreX) * layer.scale, (scaleCenter.y + screenCentreY) * layer.scale); 
    
    NSLog(@"Old CP:%f, %f", layer.position.x, layer.position.y);
    
    // Set the scale.
    layer.scale = scale;
    
    // Get the new center point.
    CGPoint newCenterPoint = ccp((scaleCenter.x + screenCentreX) * layer.scale, (scaleCenter.y + screenCentreY) * layer.scale); 
    
    // Then calculate the delta.
    CGPoint centerPointDelta  = ccpSub(oldCenterPoint, newCenterPoint);
    
    // Now adjust the layer by the delta.
    layer.position = ccpAdd(layer.position, centerPointDelta);
}

// Internal method which sets up the Box2D simulation 
-(id) initWithLevel: (BLevel *) level withDebug: (BOOL) __debug {
    if((self=[self init])) {
        _debug = __debug;
    
    NSLog(@"--- Starting to build Box2D level");
    
    _level = level;
    
    assert(_level != Nil);
    
	// Setup the gravity
    b2Vec2 gravity;
	gravity.Set(level.gravityX, level.gravityY);
	
    // Create a world
    _world = new b2World(gravity);
    
    // Allow objects to sleep
    _world->SetAllowSleeping(true);
    
    _world->SetContinuousPhysics(true);
    
    // If debug draw is enabled set it up
    if(self.debug) {
        assert(_level.screenToWorld > 0);
        // Setup debug draw
        _debugDraw = new GLESDebugDraw(1/_level.screenToWorld);
        _world->SetDebugDraw(_debugDraw);
    
        uint32 flags = 0;
        flags += b2Draw::e_shapeBit;
        //		flags += b2Draw::e_jointBit;
        //		flags += b2Draw::e_aabbBit;
        //		flags += b2Draw::e_pairBit;
        //		flags += b2Draw::e_centerOfMassBit;
        _debugDraw->SetFlags(flags);	
    }
    
    // The level must contain elements
    assert(level.elements != Nil);
    
    // Add the elements
    for(BElement * elm in level.elements) {
        if(elm == Nil) {
            continue;
        }
        
        // Create a new body definition
        b2BodyDef bd = [self parseBodyDef:[elm getTagPairListByCategory:@"body-definition"]];
        
        // Set the position and angle from the element
        bd.position = [self stwVector: [BBox2DBuilder toVec2:elm.position]];
        bd.angle = [self stwAngle:[elm rotation]];
        
        b2FixtureDef fd = [self parseFixtureDef:[elm getTagPairListByCategory:@"fixture-def"]];
        
        // Create the body
        b2Body * body = _world->CreateBody(&bd);
        
        // Add the sprite to the element
        if(elm.sprite != Nil) {
            NSLog(@"Add Sprite: %@", elm.sprite);

            CCSprite * sprite;
            
            // For packed sprites get the sprite from the frame
            if(_level.spritesPacked) {
                sprite = [CCSprite spriteWithSpriteFrameName:elm.sprite];	
            }
            // Otherwise get the sprites individually
            else {
                sprite = [CCSprite spriteWithFile:elm.sprite];	
            }
            
            // Set the sprite rotation point to the bottom left to match Box2D
            sprite.anchorPoint = ccp(0,0);
            
            // Set the sprite initial position to be the same as the body
            b2Vec2 bodyPos = [BBox2DBuilder toVec2:elm.position];
            sprite.position = ccp([self wtsFloat: bodyPos.x], [self wtsFloat: bodyPos.y]);
            
            sprite.rotation = elm.rotation;
            
            // Add a reference to the sprite to the element
            elm.spriteLink = sprite;
            
            // For convenience set the sprite in the body's user data
            //body->SetUserData(sprite);
            
            body->SetUserData(elm);
        }
        

        // Get a pointer to the object and add it to the element
        elm.physicsLink = [NSValue valueWithPointer:body] ;
        
        // If the shape is a polygon we need to create the outline
        if(elm.shapeType == kPolygon) {
            // Create a chain body for static objects or open paths
            if(bd.type==b2_staticBody || elm.triangulation == Nil || elm.shapeSubType == kOpen) {
                if(elm.outline != Nil) {
                
                    NSInteger size = [elm.outline count];
                
                    // For open shapes remove the last vertex which
                    // is also the first vertex
                    if(elm.shapeSubType == kOpen) {
                        size --;
                    }
                    
                    // Transfer the vertices into a c style array
                    b2Vec2 * vertices = new b2Vec2 [[elm.outline count]];
                    
                    for(NSInteger z=0; z<size; z++) {
                        vertices[z] = [self stwVector:[BBox2DBuilder toVec2:[elm.outline objectAtIndex:z]]];
                    }
                    
                    // Create a chain shape
                    b2ChainShape chain;
                    
                    // Create a chain from the vertices
                    if(elm.shapeSubType==kOpen)
                        chain.CreateChain(vertices,  size);
                    else 
                        chain.CreateLoop(vertices, size);
                    // Add the shape to the fixture
                    fd.shape = &chain;
                    
                    // Create the fixture on the body
                    body->CreateFixture(&fd);
                    
                    // Using chain shapes instead of edge shapes
                    
                    //for(NSInteger i=0; i<size; i++) {
                    //    b2EdgeShape es;
                    //
                    //    b2Vec2 v1 = [self stwVector:[self toVec2: [elm.outline objectAtIndex:i]]];
                    //
                    //    For the second point take the modulus of the current counter
                    //    plus one so that for closed shapes when we reach the shape size
                    //    we will go back to vertex 1 i.e. when i = size, i%size = 0
                    //    
                    //    b2Vec2 v2 = [self stwVector:[self toVec2: 
                    //                             [elm.outline objectAtIndex:(i+1)%[elm.outline count]]]];
                    //    es.Set(v1, v2);
                    //}
                }
                else {
                    NSLog(@"Warning, no outline has been specified for shape: %@", elm.name);
                }
            }
            // Create a multi fixture body for triangulated dynamic objects
            else {
                if(elm.triangulation != Nil) {
                    // Loop over shapes in the triangulation
                    for(NSArray * shapeVertices in elm.triangulation) {
                        
                        // We can't make shapes with fewer than 2 vertices
                        if([shapeVertices count] > 2) {
                            b2PolygonShape ps;
                            
                            // Transfer the vertices into a c style array
                            b2Vec2 * vertices = new b2Vec2 [[shapeVertices count]];
                            
                            NSInteger z = 0;
                            for(NSArray * vertex in shapeVertices) {
                                vertices[z++] = [self stwVector:[BBox2DBuilder toVec2:vertex]];
                            }
                            
                            // Set the vertices for the shape
                            ps.Set(vertices, [shapeVertices count]);
                            
                            // Set the shape as part of the fixture
                            fd.shape = &ps;
                            
                            // create the fixture
                            body->CreateFixture(&fd);
                        }
                        else {
                            NSLog(@"Warning, Element %@ contains triangulations with only two sides which will be ignored", elm.name);
                        }
                    }
                }
                else {
                    NSLog(@"Warning, Element %@ has no triangulation data", elm.name);
                }
            }
        }
        
        // For circles use the Box2D native Circle type
        else if(elm.shapeType == kCircle) {
            b2CircleShape c;
            
            float scaledRadius = [self stwFloat:elm.circleRadius];
            
            c.m_p.Set(scaledRadius, scaledRadius);
            c.m_radius = scaledRadius;
            
            fd.shape = &c;
            body->CreateFixture(&fd);
            
        }
    }
    }
    return self;
}



// Internal function which parses data form a body-def profile
// NSDictionary type if some data is missing Box2D's default 
// body def is used
- (b2BodyDef) parseBodyDef: (NSDictionary *) bodyDef {
    b2BodyDef bd;
    
    // Some temporary variables
    NSNumber * val;
    NSArray * vector;
    NSString * string;
    
    if(bodyDef != Nil) {
    
        val = [bodyDef objectForKey:@"fixed rotation"];

        if(val != Nil) {
            bd.fixedRotation = [val boolValue];
        }

        val = [bodyDef objectForKey:@"allow sleep"];
    
        if(val != Nil) {
            bd.allowSleep = [val boolValue];
        }

        vector = [bodyDef objectForKey:@"velocity"];
    
        if(vector != Nil && [vector count] > 1) {
            bd.linearVelocity = [self stwVector:[BBox2DBuilder toVec2:vector]];
        }

        val = [bodyDef objectForKey:@"active"];
    
        if(val != Nil) {
            bd.active = [val boolValue];
        }

        val = [bodyDef objectForKey:@"awake"];
    
        if(val != Nil) {
            bd.awake = [val boolValue];
        }
    
        string = [bodyDef objectForKey:@"type"];
    
        if(string != Nil) {
            if([string isEqualToString:@"Static"]) {
                bd.type = b2_staticBody;
            }
            else if([string isEqualToString:@"Dynamic"]) {
                bd.type = b2_dynamicBody;
            }
            else if([string isEqualToString:@"Kinematic"]) {
                bd.type = b2_kinematicBody;
            }
        }
    
        val = [bodyDef objectForKey:@"bullet"];
    
        if(val != Nil) {
            bd.bullet = [val boolValue];
        } 

        val = [bodyDef objectForKey:@"inertial scale"];

        if(val != Nil) {
            bd.gravityScale = [val floatValue];
        } 
    }

    return bd;
}

// Internal function which parses data form a fixture-definition profile
// NSDictionary type if some data is missing Box2D's default 
// body def is used
- (b2FixtureDef) parseFixtureDef: (NSDictionary *) fixtureDef {
    b2FixtureDef fd;
    
    // By default give the object a density
    fd.density = 1;
    
    // Some temporary variables
    NSNumber * val;
    
    if(fixtureDef != Nil) {
    
        val = [fixtureDef objectForKey:@"sensor"];
    
        if(val != Nil) {
            fd.isSensor = [val boolValue];
        }

        val = [fixtureDef objectForKey:@"density"];
    
        if(val != Nil) {
            fd.density = [val floatValue];
        }
    
        val = [fixtureDef objectForKey:@"friction"];
    
        if(val != Nil) {
            fd.friction = [val floatValue];
        }

        val = [fixtureDef objectForKey:@"restitution"];
        
        if(val != Nil) {
            fd.restitution = [val floatValue];
        }    
        
        val = [fixtureDef objectForKey:@"group index"];

        NSLog(@"Group Index: %i", [val intValue]);
    
        if(val != Nil) {
            NSInteger gi = [val intValue];
            if(gi!=0)
                fd.filter.groupIndex = gi;
        }
    
        val = [fixtureDef objectForKey:@"category bits"];
    
        if(val != Nil) {
            NSInteger cb = [val intValue];
            if(cb!=0)
                fd.filter.categoryBits = cb;
        }

        val = [fixtureDef objectForKey:@"mask bits"];
    
        if(val != Nil) {
            NSInteger mb = [val intValue];
            if(mb!=0)
                fd.filter.maskBits = mb;
        }
    }
    
    return fd;
}


// Update the Box2D simulation every time step
-(void) update: (ccTime) dt {
	//It is recommended that a fixed time step is used with Box2D for stability
	//of the simulation, however, we are using a variable time step here.
	//You need to make an informed choice, the following URL is useful
	//http://gafferongames.com/game-physics/fix-your-timestep/
	
	int32 velocityIterations = 8;
	int32 positionIterations = 1;
	
	// Instruct the world to perform a single step of simulation. It is
	// generally best to keep the time step and iterations fixed.
	_world->Step(dt, velocityIterations, positionIterations);
    
    
    // Loop over the sprites to update their positions and rotations
    for (b2Body* b = _world->GetBodyList(); b; b = b->GetNext())
	{
		if (b->GetUserData() != NULL) {
			//Synchronize the AtlasSprites position and rotation with the corresponding body
			BElement * elm = (BElement*)b->GetUserData(); 
            
            CCSprite *myActor = [elm spriteLink];
            
			myActor.position = CGPointMake( [self wtsFloat: b->GetPosition().x], [self wtsFloat: b->GetPosition().y ]);
			myActor.rotation = -1 * CC_RADIANS_TO_DEGREES(b->GetAngle());
		}
	}
}

-(void) orderByZPosition: (CCLayer *) layer {
    for(BElement * elm in _level.elements) {
        [layer reorderChild:elm.spriteLink z:elm.zPosition];
    }
}

// If debug is enabled add the debug info to the display
-(void) draw {
    if(self.debug) {
        ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position );
	
        kmGLPushMatrix();
            _world->DrawDebugData();	
        kmGLPopMatrix(); 
    }
}

// Method which covertes an Array of two NSNumbers
// to a Box2D vector
+(b2Vec2) toVec2: (NSArray *) vector {
    b2Vec2 vec;
    vec.Set([[vector objectAtIndex:0] floatValue],[[vector objectAtIndex:1] floatValue]);
    return vec;
}

// Convert an angle from screen to world i.e. degrees to radians
-(float) stwAngle: (float) angle {
    return angle * 3.1415926 / 180;
}

// Convert an angle from world to screen ie. radians to degrees
-(float) wtsAngle: (float) angle {
    return angle * 180 / 3.1415926;
}

// Convert a float from screen to world coordinates
-(float) stwFloat: (float) value {
    return value * _level.screenToWorld;
}

// Convert a float from world to screen coordinates
-(float) wtsFloat: (float) value {
    return value / _level.screenToWorld;
}

// Convert a vector from screen to world coordinates 
-(b2Vec2) stwVector: (b2Vec2) vector {
    return b2Vec2([self stwFloat:vector.x], [self stwFloat:vector.y]);
}

// Convert a vector from world to screen coordinates 
-(b2Vec2) wtsVector: (b2Vec2) vector {
    return b2Vec2([self wtsFloat:vector.x], [self wtsFloat:vector.y]);
}

-(void) dealloc
{
	delete _world;
	_world = NULL;
	
	delete _debugDraw;
	_debugDraw = NULL;
	
	[super dealloc];
}	



@end
