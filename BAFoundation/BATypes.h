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
    BAQuadrant00,
    BAQuadrant01,
    BAQuadrant10,
    BAQuadrant11,
    BAQuadrant0 = BAQuadrant00,
    BAQuadrant1 = BAQuadrant01,
    BAQuadrant2 = BAQuadrant11,
    BAQuadrant3 = BAQuadrant10
};
