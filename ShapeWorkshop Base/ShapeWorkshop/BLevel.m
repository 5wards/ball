//
//  BLevel.m
//  Introduction to Physics
//
//  Created by Ben Smiley-Andrews on 23/05/2012.
//  Copyright (c) 2012 Deluge. All rights reserved.
//

#import "BLevel.h"

@implementation BLevel

@synthesize gravityX;
@synthesize gravityY;
@synthesize screenToWorld;
@synthesize scale;
@synthesize spritesPacked;

@synthesize elements = _elements;

-(id) init {
    if((self=[super init])) {
        _elements = [NSMutableArray new];
        
        self.scale = 1;
    }
    return self;
}

// Create a level from the contents of a Shape Workshop geometry file
+(id) levelWithContentsOfFile:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        NSLog(@"The file exists");
    } else {
        NSLog(@"The file does not exist");
    }
    
    NSDictionary * level = [[NSDictionary alloc] initWithContentsOfFile:path];

    assert(level != Nil);
    
    return [[self alloc] initBLevel:level];
    
}

// Internal init method to add properties form 
// dictionary to this object
-(id) initBLevel: (NSDictionary *) level {
    if((self=[super init])) {
        
        NSLog(@"--- Start processing level: %@", [level objectForKey:@"name"]);
        
        // Set the value of the gravity
        NSArray * gravity = [self getGravity:level];    
        if(gravity!=Nil) {
            self.gravityX = [[gravity objectAtIndex:0] doubleValue];
            self.gravityY = [[gravity objectAtIndex:1] doubleValue];
        }
        
        NSLog(@"--- Gravity: %f, %f", self.gravityX, self.gravityY);
        
        // Set the screen to world value
        self.screenToWorld = [self getScreenToWorld: level];
        
        assert(self.screenToWorld > 0);
        
        NSLog(@"--- Screen to world: %f", self.screenToWorld);
        
        self.spritesPacked = [self areSpritesPacked:level];

        self.scale = [self getScale:level];
        
        _elements = [self getElements:level];
        
        NSLog(@"--- Processing finished, %i elements created", [_elements count]);
        
    }
    return self;
}

// Process an element from the dictionary
-(NSMutableArray *) getElements: (NSDictionary*) level {
    NSMutableArray * elements = [NSMutableArray new];

    if(level != Nil) {
        NSArray * elms = [level objectForKey:@"elements"];
        
        NSLog(@"--- Start processing %i element(s)", [elms count]);
        
        if(elms != Nil) {
            BElement * elm;
            for(NSDictionary * dictElm in elms) {
                elm = [BElement elementWithContentsOfDictionary:dictElm];
                [elements addObject:elm];
            }
        }
        else {
            NSLog(@"Warning, no elements found");
        }
    }
    return elements;
}

// Get whether the sprites are packed from the level dictionary
- (BOOL) areSpritesPacked: (NSDictionary *) level {
    NSNumber * packed = [level objectForKey:@"sprites-packed"];
    assert(packed!=Nil);
    
    return [packed boolValue];
}

// Get the level scale from the dictionary
- (double) getScale: (NSDictionary * ) level {
    double aScale = 1.0;
    if([level objectForKey:@"scale"] != Nil) {
        aScale = [[level objectForKey:@"scale"] floatValue];
        if(aScale == 0)
            return 1.0;
    }    
    return aScale;
}

// Get the gravity vector for the level
-(NSArray*) getGravity: (NSDictionary *) level {
    if(level!=Nil) {
        return [level objectForKey:@"gravity"];
    }
    return Nil;
}

// Get a list of elements for a given name
-(NSMutableArray *) getElementsByName: (NSString *) name {
    NSMutableArray * elementsWithName = [NSMutableArray new];
    if(_elements != Nil) {
        for(BElement * elm in _elements) {
            if([elm.name isEqualToString:name]) {
                [elementsWithName addObject:elm];
            }
        }
    }
    return elementsWithName;
}

// Get a list of elements which contain a given tag
-(NSMutableArray *) getElementsByTag: (NSString *) tag {
    NSMutableArray * elementsWithTag = [NSMutableArray new];
    if(_elements != Nil) {
        for(BElement * elm in _elements) {
            if([elm containsTag:tag]) {
                [elementsWithTag addObject:elm];
            }
        }
    }
    return elementsWithTag;
}

// Get the ratio of the display size i.e. sprite dimensions
// to the simulation dimensions. This is important because 
// physics engines are optimised to work with real world 
// dimensions i.e. 0.1m -> 20m if you use 1px = 1m you'll
// end up having huge objects which will make the simulation 
// buggy
-(double) getScreenToWorld: (NSDictionary *) level {
    if(level!=Nil) {
        NSNumber * stw = [level objectForKey:@"screenToWorld"];
        if(stw != Nil ) {
            return [stw floatValue];
        }
    }
    return 1;
}

-(void) dealloc {
    [_elements release];
    [super dealloc];
}



@end
