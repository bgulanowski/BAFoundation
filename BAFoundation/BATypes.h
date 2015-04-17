//
//  BATypes.h
//  BAFoundation
//
//  Created by Brent Gulanowski on 2015-04-13.
//  Copyright (c) 2015 Lichen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct {
    NSInteger x;
    NSInteger y;
} BAPoint2;

typedef struct {
    NSInteger width;
    NSInteger height;
} BASize2;

typedef struct {
    BAPoint2 origin;
    BASize2 size;
} BARegion2;

typedef NS_ENUM(NSUInteger, BAQuadrant) {
    BAQuadrant00 = 0x01, // +X, +Y
    BAQuadrant01 = 0x02, // -X, +Y
    BAQuadrant10 = 0x04, // +X, -Y
    BAQuadrant11 = 0x08, // -X, -Y
    BAQuadrant0 = BAQuadrant00,
    BAQuadrant1 = BAQuadrant01,
    BAQuadrant2 = BAQuadrant11,
    BAQuadrant3 = BAQuadrant10,
    BAPositiveX = BAQuadrant00 | BAQuadrant10,
    BANegativeX = BAQuadrant01 | BAQuadrant11,
    BAPositiveY = BAQuadrant00 | BAQuadrant01,
    BANegativeY = BAQuadrant10 | BAQuadrant11,
    BAQuadrantsAll = BAPositiveX | BANegativeX
};
