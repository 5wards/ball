//
//  BElement.m
//  Introduction to Physics
//
//  Created by Ben Smiley-Andrews on 23/05/2012.
//  Copyright (c) 2012 Deluge. All rights reserved.
//

#import "BElement.h"

@implementation BElement

@synthesize name;
@synthesize position = _position;
@synthesize dimensions = _dimensions;
@synthesize rotation;

@synthesize shapeType;
@synthesize shapeSubType;
@synthesize outline = _outline;
@synthesize triangulation = _triangulation;
@synthesize physicsLink = _physicsLink;

@synthesize circlePositionX;
@synthesize circlePositionY;
@synthesize circleRadius;

@synthesize sprite;
@synthesize spriteOffset = _spriteOffset;
@synthesize spriteLink = _spriteLink;

@synthesize tags = _tags;
@synthesize profiles = _profiles;

@synthesize zPosition;



-(id) init {
    if((self=[super init])) {
        
    }
    return self;
}

// Create an element from an element file
+(id) elementWithContentsOfFile:(NSString *)path {
    NSDictionary * element = [[NSDictionary alloc] initWithContentsOfFile:path];
    return [[self alloc] initBLevel:element];
}

// Create an element form an element dictionary definition
+ (id) elementWithContentsOfDictionary: (NSDictionary *) element {
    return [[self alloc] initBLevel:element];
}


// Internal init method
-(id) initBLevel: (NSDictionary *) element {
    if((self=[super init])) {
        
        if(element != Nil) {
            
            
            self.name = [element objectForKey:@"name"];

            NSLog(@"----- Start processing element: %@", self.name);

            _position = [element objectForKey:@"position"];

            NSLog(@"----- Position: %f, %f", [[_position objectAtIndex:0] floatValue], 
                                             [[_position objectAtIndex:1] floatValue]);
            
            self.rotation = [[element objectForKey:@"rotation"] floatValue];
            
            NSLog(@"----- Rotation: %f", self.rotation);
            
            self.zPosition = [[element objectForKey:@"z-position"] intValue];
            
            _dimensions = [element objectForKey:@"dimensions"];
            
            NSDictionary * shape = [element objectForKey:@"shape"];
            if(shape != Nil) {
                
                // Get the shape type
                NSString * type = [shape objectForKey:@"type"];
                if([type isEqualToString:@"polygon"]) {
                    self.shapeType = kPolygon;
                    
                    NSString * subType = [shape objectForKey:@"sub-type"];
                    if(subType != Nil) {
                        if([subType isEqualToString:@"open"]) {
                            self.shapeSubType = kOpen;
                        }
                        else if([subType isEqualToString:@"closed"]) {
                            self.shapeSubType = kClosed;
                        }
                    }
                    
                    NSLog(@"----- Shape type: %@", type);
                    
                    // Get the outline
                    _outline = [shape objectForKey:@"outline"];
                    _triangulation = [shape objectForKey:@"triangulation"];
                    
                }
                else if([type isEqualToString:@"circle"]) {
                    self.ShapeType = kCircle;
                    
                    circlePositionX = [[shape objectForKey:@"x"] floatValue];
                    circlePositionY = [[shape objectForKey:@"y"] floatValue];
                    circleRadius = [[shape objectForKey:@"r"] floatValue];

                }
            }
            
            NSDictionary * aSprite = [element objectForKey:@"sprite"];
            if(aSprite != Nil) {
                self.sprite = [aSprite objectForKey:@"file-name"];
                self.spriteOffset = [aSprite objectForKey:@"offset"];
                
                NSLog(@"----- Sprite: %@", self.sprite);
            }
            
            _tags = [element objectForKey:@"tags"];
            
            _profiles = [element objectForKey:@"profiles"];
            
        }

    }
    return self;
}

// Get the starting x-position of this element
-(float) getX {
    if(_position!=Nil) {
        return [[_position objectAtIndex:0] floatValue];
    }
    NSLog(@"BElement.getX failed because position is Nil");
    return 0;
}

// Get the starting y-position of this element
-(float) getY {
    if(_position!=Nil) {
        return [[_position objectAtIndex:1] floatValue];
    }
    NSLog(@"BElement.getY failed because position is Nil");
    return 0;
}

// Get a tag profile by providing it's name
-(NSDictionary *) getProfileByName: (NSString*) aName {
    for(NSDictionary * profile in _profiles) {
        if ([[profile objectForKey:@"name"] isEqualToString:aName] ) {
            return profile;
        }
    }
    return Nil;
}

// Get a tag pair list by profiding the profile name
-(NSDictionary *) getTagPairListByName: (NSString *) aName {
    NSDictionary * profile = [self getProfileByName:aName];
    if(profile != Nil) {
        return [profile objectForKey:@"tag-pairs"];
    }
    return Nil;
}

// If the element contains the tag return true
-(BOOL) containsTag: (NSString *) tag {
    for(NSString * t in _tags) {
        if([t isEqualToString:tag]) {
            return YES;
        }
    }
    return NO;
}

// Get a profile by providing it's category
-(NSDictionary *) getProfileByCategory: (NSString*) aCategory {
    for(NSDictionary * profile in _profiles) {
        if ([[profile objectForKey:@"category"] isEqualToString:aCategory] ) {
            return profile;
        }
    }
    return Nil;
}

// Get a tag pair list by providing the profile category
-(NSDictionary *) getTagPairListByCategory: (NSString *) aCategory {
    NSDictionary * profile = [self getProfileByCategory:aCategory];
    if(profile != Nil) {
        return [profile objectForKey:@"tag-pairs"];
    }
    return Nil;
}

-(void) dealloc {
    [_position release];
    [_dimensions release];

    [_outline release];
    [_triangulation release];

    [_spriteOffset release];
    [_tags release];
    [_profiles release];
    
    [_physicsLink release];
    
    [super dealloc];
}

@end
