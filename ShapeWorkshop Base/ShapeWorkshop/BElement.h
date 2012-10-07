//
//  BElement.h
//  Introduction to Physics
//
//  Created by Ben Smiley-Andrews on 23/05/2012.
//  Copyright (c) 2012 Deluge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCSprite.h"

typedef enum {
    kCircle,
    kPolygon,
    kOpen,
    kClosed
} ShapeType;

@interface BElement : NSObject {
    
    /*
     * For flexibility all vector values are stored in NSArray as 
     * NSNumbers. For example NSArray * position. 
     * [[position objectAtIndex: 0] floatValue] = x
     * [[position objectAtIndex: 1] floatValue] = y
     *
     * See method BBox2DBuilder.toVec2 an example
     */
    
    // The position of the element
    NSArray * _position;
    
    // The dimensions of the elements bounding box
    NSArray * _dimensions;
    
    // For polygons
    // A 2D array of out outline vertices of the shape. 
    NSArray * _outline;
    
    // An array of outlines for the elements which make up
    // the triangulation
    NSArray * _triangulation;
    
    // The vector coordinates of the sprite offset if there is one
    NSArray * _spriteOffset;
    
    // A string array of tags as defined in ShapeWorkshop
    NSArray * _tags;
    
    // An array of dictionaries which represent the active
    // profiles for the object
    NSArray * _profiles;
    
    // A weak reference to the body stored in an NSValue 
    __weak NSValue * _physicsLink;
    
    // A weak reference to the CCSprite in Cocos2D
    __weak CCSprite * _spriteLink;
    
}

// General
@property (nonatomic, readwrite, retain) NSString* name;
@property (nonatomic, readwrite, retain) NSArray* position;
@property (nonatomic, readwrite, retain) NSArray* dimensions;

// The rotation angle of the element
@property (nonatomic, readwrite) float rotation;

// Shape
// Circle or Polygon
@property (nonatomic, readwrite) ShapeType shapeType;
// Open or closed path
@property (nonatomic, readwrite) ShapeType shapeSubType;


@property (nonatomic, readwrite, retain) NSArray* outline;
@property (nonatomic, readwrite, retain) NSArray* triangulation;

// The attributes of the circle if the shape is a circle
@property (nonatomic, readwrite) float circlePositionX;
@property (nonatomic, readwrite) float circlePositionY;
@property (nonatomic, readwrite) float circleRadius;

@property (nonatomic, readwrite, retain) NSValue * physicsLink;

// Sprite
@property (nonatomic, readwrite, retain) NSString * sprite;
@property (nonatomic, readwrite, retain) NSArray * spriteOffset;
@property (nonatomic, readwrite, retain) CCSprite * spriteLink;

// Tags
@property (nonatomic, readwrite, retain) NSArray* tags;
@property (nonatomic, readwrite, retain) NSArray* profiles;

// The image's z-position higher -> further forward
@property (nonatomic, readwrite) int zPosition;

+(id) elementWithContentsOfFile:(NSString *) path;
+ (id) elementWithContentsOfDictionary: (NSDictionary *) element;

-(NSDictionary *) getProfileByName: (NSString*) aName;
-(NSDictionary *) getTagPairListByName: (NSString *) aName;
-(NSDictionary *) getProfileByCategory: (NSString*) aName;
-(NSDictionary *) getTagPairListByCategory: (NSString *) aName;
-(float) getX;
-(float) getY;
-(BOOL) containsTag: (NSString *) tag;


@end
