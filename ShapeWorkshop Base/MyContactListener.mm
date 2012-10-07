//
//  MyContactListener.m
//  ShapeWorkshop Base
//
//  Created by Ben Smiley-Andrews on 07/06/2012.
//  Copyright (c) 2012 Deluge. All rights reserved.
//

#import "MyContactListener.h"

void MyContactListener::BeginContact(b2Contact* contact) {
    
    // Extract the elements from the contact
    BElement * elmA = (BElement *) contact->GetFixtureA()->GetBody()->GetUserData();
    BElement * elmB = (BElement *) contact->GetFixtureB()->GetBody()->GetUserData();
    
    // Cast the layer variable to a HelloWorldLayer
    HelloWorldLayer * hwl = (HelloWorldLayer *) _layer;
    
    // Call the start contact method and pass it the two elements
    [hwl startContact:elmA withElmB:elmB];
}

void MyContactListener::EndContact(b2Contact* contact) {
    BElement * elmA = (BElement *) contact->GetFixtureA()->GetBody()->GetUserData();
    BElement * elmB = (BElement *) contact->GetFixtureB()->GetBody()->GetUserData();
    
    HelloWorldLayer * hwl = (HelloWorldLayer *) _layer;
    
    [hwl endContact:elmA withElmB:elmB];
    

}
