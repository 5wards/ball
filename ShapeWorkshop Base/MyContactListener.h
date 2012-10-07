//
//  MyContactListener.h
//  ShapeWorkshop Base
//
//  Created by Ben Smiley-Andrews on 07/06/2012.
//  Copyright (c) 2012 Deluge. All rights reserved.
//

#import "Box2D.h"
#import "b2Contact.h"
#import "b2ContactManager.h"
#import "b2ContactSolver.h"
#import "CCLayer.h"
#import "HelloWorldLayer.h"

class MyContactListener : public b2ContactListener
{
    public:
    // Setup a new contact listener by passing in a CCLayer
    MyContactListener (CCLayer * layer) {
        _layer = layer;
    }
    
	virtual void BeginContact(b2Contact* contact); 
	virtual void EndContact(b2Contact* contact);
    
    CCLayer * _layer;
};
