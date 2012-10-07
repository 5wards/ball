//
//  BLevel.h
//  Introduction to Physics
//
//  Created by Ben Smiley-Andrews on 23/05/2012.
//  Copyright (c) 2012 Deluge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BElement.h"

@interface BLevel : NSObject {
    NSMutableArray * _elements;
}

@property (nonatomic, readwrite) float gravityX;
@property (nonatomic, readwrite) float gravityY;
@property (nonatomic, readwrite) float screenToWorld;
@property (nonatomic, readwrite) float scale;
@property (nonatomic, readwrite) BOOL spritesPacked;

@property (nonatomic, readwrite, retain) NSMutableArray * elements;

+(id) levelWithContentsOfFile: (NSString *) path;

-(NSMutableArray *) getElementsByTag: (NSString *) tag;
-(NSMutableArray *) getElementsByName: (NSString *) name;

@end
