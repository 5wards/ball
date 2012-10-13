//
//  HelloWorldLayer.mm
//  ShapeWorkshop Base
//
//  Created by Ben Smiley-Andrews on 28/05/2012.
//  Copyright Deluge 2012. All rights reserved.
//

// Import the interfaces
#import "HelloWorldLayer.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"



#pragma mark - HelloWorldLayer


@implementation HelloWorldLayer


+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

-(id) init
{
	if( (self=[super init])) {
		
        /*
         * Setting up the world
         */
        self.isAccelerometerEnabled = YES;
        // Get a link to the level config file
        NSString * path = [[NSBundle mainBundle] pathForResource:@"labyrinth" ofType:@"plist"];
        
        // Create a new Level object from the file
        _level = [BLevel levelWithContentsOfFile:path];
        
        // Add the sprite sheet to Cocos2D
        [BBox2DBuilder setSpriteSheet:self withSpriteSheet:@"labyrinth-spritesheet1.png" withPackFile:@"labyrinth-pack.plist"];
        
        // Build the Box2D world
        _builder =  [BBox2DBuilder box2DBuilderWithLevel:_level withDebug:NO];
        _world = [_builder world];
        
        // Add individual element's sprites to the layer
        [_builder addSpritesToLayer:self];

        // Set the scale to match what we've setup in Shape Workshop
        [_builder setScaleFromLevel:self];
        
        // Set the sprite positioning in the z-direction to match Shape Workshop
        [_builder orderByZPosition:self];
        
        // Start the physics world running
        _runPhysics = YES;
        
        // get a pointer to our ball for use later on
        // Get elements by tag could return multiple items however in this case we've
        // only added the tag ball to one element
        NSMutableArray * ball = [_level getElementsByTag:@"ball"];
        if(ball != Nil && [ball count] > 0) {
            _ball = [ball objectAtIndex:0];

            // A pointer to the Box2D body is stored in the physics link member variable
            // as an NSValue
            NSValue * bodyValue = _ball.physicsLink;
            b2Body * ballBody;
            
            // Extract the body from the NSValue object
            [bodyValue getValue:&ballBody];
            
            // Record the starting position of the ball for later
            _startPosition = ballBody->GetPosition();
        }

        // Get a pointer to the fan
        NSMutableArray * fan = [_level getElementsByTag:@"fan"];
        if(fan != Nil && [fan count] > 0) {
            _fan = [fan objectAtIndex:0];
        }

        // Enable touches for Cocos2D
        self.isTouchEnabled = YES;

        // Setup our custom contact listener with a callback to this class
        // whenever there's a collision
        _contactListener = new MyContactListener(self);
        
        // Add the contact listener to the Box2D world
        _builder.world->SetContactListener(_contactListener);

        // Setup the animation for when the ball falls in a hole
        
        
        // Access the shared frames cache - global store of frames
        CCSpriteFrameCache * cache = [CCSpriteFrameCache sharedSpriteFrameCache];
        
        // Load the available frames from the sprite sheet
        [cache addSpriteFramesWithFile:@"ball_falling_anim.plist" textureFilename:@"ball_falling_anim.png"];
        
        // Create an array of frames - stored as a member variable
        NSMutableArray *ballFrames = [NSMutableArray new];
        for(NSInteger i =1; i<15; i++) {
            // The names of the objects in the sprite sheet are the same as the images files
            // before they are loaded into the sprite sheet i.e. ball-1, ball-2 etc...
            //NSLog(@"Frame:%@", [NSString stringWithFormat:@"ball-%i", i]);
            [ballFrames addObject:[cache spriteFrameByName:[NSString stringWithFormat:@"ball-%i.png", i]]];
        }
        
        // Put these frames in a normal NSArray member variable
        _ballAnimationFrames = [NSArray arrayWithArray:ballFrames];
        [_ballAnimationFrames retain];

        // Setup the menu for when the player completes the level
        _button = [CCMenuItemImage itemWithNormalImage:@"end_menu.png" selectedImage:@"end_menu.png" block:^(id) {
            if(_ball != Nil) {
                // Get the ball's box2d body
                NSValue * bodyValue = _ball.physicsLink;
                b2Body * ballBody;
                
                [bodyValue getValue:&ballBody];
                
                // Return the ball to it's start position
                ballBody->SetTransform(_startPosition, 0);
                ballBody->SetAwake(YES);
                
                // Set the physics running
                _runPhysics = YES;
                
                // Make the sprite visible again
                _ball.spriteLink.visible = YES;
                
                // Hide this menu
                _menu.visible = NO;
                
            }
        }];
        
        // Add the button to the menu
        _menu = [CCMenu menuWithItems: _button, nil];
        // Hide the menu
        _menu.visible = NO;
        // Position the menu in the centre of the screen
        _menu.position = ccp(480, 320);
		
        // Add the menu to this layer
        [self addChild:_menu z:200];
        
		[self scheduleUpdate];
	}
	return self;
}


// Called when the ball collides with something
-(void) startContact: (BElement *) elmA withElmB: (BElement *) elmB {
    // If the ball hits a wall
    if([self testElements:elmA withElmB:elmB withTag:@"hole" withTag2:@"ball"]) {
        // We want to shrink the ball as if it's falling and move it towarsd the centre of the hole
        // we will add a pointer to the hole and then check every loop if the ball is sufficiently
        // into the hole i.e. it won't fall if the ball just touches the hole the ball needs to be
        // half over the hole as it would in real life
        if([elmA containsTag:@"hole"]) {
            _hole = elmA;
        }
        else {
            _hole = elmB;
        }
    }
    
    // If the ball hits the bouncer
    if([self testElements:elmA withElmB:elmB withTag:@"bouncer" withTag2:@"ball"]) {
        // Get the position of the bouncer
        BElement * bouncer;
        
        if([elmA containsTag:@"bouncer"]) {
            bouncer = elmA;
        }
        else {
            bouncer = elmB;
        }
        
        // Find the vector from the centre of the bouncer and the centre of the ball
        float xComp = (_ball.spriteLink.position.x + _ball.spriteLink.boundingBox.size.width/2 ) - (bouncer.spriteLink.position.x + bouncer.spriteLink.boundingBox.size.width/2);
        
        float yComp = (_ball.spriteLink.position.y + _ball.spriteLink.boundingBox.size.height/2 ) - (bouncer.spriteLink.position.y + bouncer.spriteLink.boundingBox.size.height/2);
        
        // Define the force of the bouncer
        float forceFactor = 3;
        
        b2Vec2 force (xComp * forceFactor, yComp * forceFactor);
        
        // Get the body associated with the ball
        NSValue * bodyValue = _ball.physicsLink;
        b2Body * ballBody;
        [bodyValue getValue:&ballBody];
        
        // Apply an impulse to the ball
        ballBody->ApplyLinearImpulse(force, ballBody->GetWorldCenter());
        
        // Animate the bouncer
        id scaleUp = [CCScaleTo actionWithDuration:0.05 scale:1.2];
        id scaleDown = [CCScaleTo actionWithDuration:0.05 scale:1]; 
        
        [bouncer.spriteLink runAction:[CCSequence actions:scaleUp, scaleDown, nil]];
    }
    
    // If the ball reaches the end zone show the "play again" menu
    if([self testElements:elmA withElmB:elmB withTag:@"endzone" withTag2:@"ball"]) {
        _menu.visible = TRUE;
        _runPhysics = NO;
    }
}

-(void) endContact: (BElement *) elmA withElmB: (BElement *) elmB {
    if([self testElements:elmA withElmB:elmB withTag:@"hole" withTag2:@"ball"]) {
        // If the ball leaves the hole without getting sufficently close set the 
        // hole pointer to Nil
        _hole = Nil;
    }
}

// A helper function to let us know if a collision has occurred between two objects
-(BOOL) testElements: (BElement *) elmA withElmB: (BElement *) elmB withTag: (NSString *) tag1 withTag2: (NSString *) tag2 {
    if(([elmA containsTag:tag1] && [elmB containsTag:tag2]) ||
       ([elmB containsTag:tag1] && [elmA containsTag:tag2])) {
        return YES;
        
    }
    return NO;
}
 

- (void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch* touch = [touches anyObject];
    [self updateBallForce:touch];
    
}

- (void) ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch* touch = [touches anyObject];
    [self updateBallForce:touch];
}

-(void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    b2Vec2 force (0,0);
    _ballForce = force;
    NSLog(@"Force: %f, %f", _ballForce.x, _ballForce.y);
}

- (void) updateBallForce: (UITouch *) touch {
    
    // Get the location of the touch
    CGPoint location = [touch locationInView:touch.view];
    
    // Find the position relative to the centre of the screen
    // remember the screen is 480x320 with the origin at the 
    // top left hand corner
    float xRel = location.x - 240;
    // Make it so y-up is positive negative
    float yRel = -location.y + 160;
    
    // Scale xRel and yRel so they vary between 0 and 1
    xRel = xRel / 240;
    yRel = yRel / 160;
    
    
    // Now apply a force to the ball 
    float maxForce = 15 ;
    
    // Check that there is a ball
    if(_ball != Nil) {
        b2Body * ballBody;
        
        // The body is stored as a pointer wrapped in an NSValue
        // get a reference to the NSValue
        NSValue * bodyValue = _ball.physicsLink;
        
        // Populate ballBody with the reference
        [bodyValue getValue:&ballBody];
        
        // Set the linear damping. This means that if the ball
        // will gradually come to rest if we don't tilt the 
        // phone. 
        ballBody->SetLinearDamping(0.5);
        
        // Make sure the body is awake
        ballBody->SetAwake(YES);
        
        // Create a new force depending on where we've touched on the screen
        b2Vec2 force (xRel * maxForce * ballBody->GetMass(), yRel * maxForce* ballBody->GetMass());
        _ballForce = force;
        
        
        
        
    }    
}




-(void) endAnimation {
    // When the animation comes to an end hide the ball
    _ball.spriteLink.visible = NO;

    // Reset it's sprite to scale 1
    _ball.spriteLink.scale = 1;
    
    // Get hold of the Box2D body
    NSValue * bodyValue = _ball.physicsLink;
    b2Body * ballBody;
    
    [bodyValue getValue:&ballBody];
    
    // Move it back to the start position
    b2Vec2 ballPos = ballBody->GetPosition();
    NSLog(@"Position: %f, %f", ballPos.x, ballPos.y);
    //NSLog(@"Sila: %f, %f", ballBody->GetLinearVelocity.Length(), _ballForce.y); //_ballForce.x!=0 && _ballForce.y
    int xTransform;
    if (ballBody->GetLinearVelocity().x < 0)
    {
        xTransform = 44;
    } else {xTransform = -44;}
    NSLog(@"Speed: %f, %f", ballBody->GetLinearVelocity().x, _ballForce.y); //_ballForce.x!=0 && _ballForce.y
    ballBody->SetTransform(b2Vec2(ballPos.x + xTransform, ballPos.y), ballBody->GetAngle()); //
    
    // The animation will have change the sprite frame. To reset
    // this we need to set the displayed frame back to the original ball
    [_ball.spriteLink setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:_ball.sprite]];
    
    // Make the ball visible again
    _ball.spriteLink.visible = YES;
    
    // Restart physics
    _runPhysics = YES;
    
}


-(void) triggerFallAnimation {
    // Stop the physics engine from updating
    _runPhysics = NO;
    
    // Get the position of the hole
    //CGPoint holePos = _hole.spriteLink.position;
    // Get the hole size
    //CGSize holeSize = _hole.spriteLink.boundingBox.size;
    
    // Move the ball to the centre of the hole
    //id move = [CCMoveTo actionWithDuration:0.1  position:ccp(holePos.x + holeSize.width*0.1,
     //                                                      holePos.y + holeSize.height*0.1)];
    // Shrink the ball to 80% of it's normal size
    id shrink = [CCScaleTo actionWithDuration:0.1 scale:0.8];
    
    // Setup the frame by frame rolling animation
    id animate = [CCAnimate  actionWithAnimation:[CCAnimation animationWithSpriteFrames:_ballAnimationFrames]];
    
    // When the animation has ended call the endAnimation function
    id end = [CCCallFunc actionWithTarget:self selector:@selector(endAnimation)];
    
    // Put these actions into a sequence and run them
    [_ball.spriteLink runAction:[CCSequence actions:animate, end, nil]];
}
 

-(void) dealloc
{

	
	[super dealloc];
}	



-(void) draw
{
	[super draw];
    [_builder draw];
}


-(void) update: (ccTime) dt
{

    // If we've not paused the physics engine update the physics world
    if(_runPhysics)
        [_builder update:dt];
    

    
     
    b2Body * ballBody;
    NSValue * bodyValue;
    
    // Apply a force to the ball
    if(_ball != Nil) {
        // Apply the force to the ball
        
        bodyValue = _ball.physicsLink;
        [bodyValue getValue:&ballBody];
        
        if(_ballForce.x!=0 && _ballForce.y != 0) {
            ballBody->ApplyForce(_ballForce, ballBody->GetWorldCenter());
        }
    }
    
    // Check if the ball is over half in the hole
    if(_runPhysics) {
        CGPoint holePos = _hole.spriteLink.position;
        CGPoint ballPos = _ball.spriteLink.position;
        
        //NSLog(@"ball.position: %f, %f", _ball.spriteLink.position.x, _ball.spriteLink.position.y);
        
        // Calculate the distance of ball from the hole
        float dist = sqrtf(powf(holePos.x - ballPos.x, 2) + powf(holePos.y - ballPos.y, 2));
        //NSLog(@"Sila: %f, %f", ballBody->GetLinearVelocity.Length(), _ballForce.y); //_ballForce.x!=0 && _ballForce.y
        // If the distance is less than 50% of the balls width it will fall
        // This is because in reality the contact surface of the ball on the
        // wood is very small and occurs at 50% of the balls width. Only when
        // this contact area is in the hole will the ball fall.
    
        //NSLog(@"Sila: %f, %f", ballBody->GetLinearVelocity().x, _ballForce.y); //_ballForce.x!=0 && _ballForce.y
        if(ballPos.x < 25 && ballBody->GetLinearVelocity().x < 0) {
            [self triggerFallAnimation];
        }
        if(ballPos.x > 875 && ballBody->GetLinearVelocity().x > 0) {
            [self triggerFallAnimation];
        }
    }
    
    
    // Apply the repulsive effect of the fan
    
    if( _fan != Nil && _ball!= Nil) {

            bodyValue = _ball.physicsLink;
            [bodyValue getValue:&ballBody];
        
            float xComp = (_ball.spriteLink.position.x + _ball.spriteLink.boundingBox.size.width/2 ) - (_fan.spriteLink.    position.x + _fan.spriteLink.boundingBox.size.width/2);
        
            float yComp = (_ball.spriteLink.position.y + _ball.spriteLink.boundingBox.size.height/2 ) - (_fan.spriteLink.position.y + _fan.spriteLink.boundingBox.size.height/2);
        
            float distSq = powf(xComp, 2) + powf(yComp, 2);
            
            
            float forceFactor = 5000;
        
            // Inverse squared force - will be tiny at any great distance
            b2Vec2 force (forceFactor * (xComp / fabsf(xComp)) / distSq, forceFactor * (yComp/fabsf(xComp))/distSq);


            if(force.x > 10) {
            //    force.x = 10;
            }
            if(force.y > 10) {
            //    force.y = 10;
            }
            
        
            
            NSLog(@"Fan Force: %f, %f", force.x, force.y);
            
            ballBody->ApplyForce(force, ballBody->GetWorldCenter());
        
        
    }
}


-(void) accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
    
    if(_ball != Nil) {
    	// Get a pointer to the ball's physics body
        b2Body * ballBody;
        NSValue * bodyValue = _ball.physicsLink;
        [bodyValue getValue:&ballBody];
        
        // Make sure the body is awake (if it's not awake it won't be affected by gravity)
        ballBody->SetAwake(YES);
    }
    
    // Set the gravity by the tilt angle
    b2Vec2 gravity ( 40 * acceleration.y, - 40 * acceleration.x);
    NSLog(@"Gravity: %f, %f", gravity.x, gravity.y);
    _world->SetGravity(gravity);
    NSLog(@"Acceleration: %f, %f, %f", acceleration.x, acceleration.y, acceleration.z);
}

@end
