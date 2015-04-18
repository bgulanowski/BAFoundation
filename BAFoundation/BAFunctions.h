//
//  BAFunctions.h
//  BAFoundation
//
//  Created by Brent Gulanowski on 13-03-15.
//  Copyright (c) 2013 Lichen Labs. All rights reserved.
//

#ifndef BAFoundation_BAFunctions_h
#define BAFoundation_BAFunctions_h

#import <BAFoundation/BAMacros.h>
#import <BAFoundation/BATypes.h>

NS_INLINE NSInteger BARandomIntegerInRange(NSInteger min, NSInteger max) {
	NSInteger result = (NSInteger)BARandomCGFloatInRange((CGFloat)min, (CGFloat)max+1);
	return result > max ? max : result;
}

NS_INLINE NSInteger powi ( NSInteger base, NSUInteger exp ) {
    NSInteger result = base ? 1 : 0;
    while(exp) {
        if (exp & 1)
            result *= base;
        exp >>= 1;
        base *= base;
    }
    return result;
}

NS_INLINE uint32_t NextPowerOf2( uint32_t v ) {
    
    v--;
    v |= v >> 1;
    v |= v >> 2;
    v |= v >> 4;
    v |= v >> 8;
    v |= v >> 16;
    v++;
    
    return v;
}

NS_INLINE NSUInteger countBits(BOOL *bits, NSUInteger length) {
    NSUInteger count = 0;
    for (NSUInteger i=0; i<length; ++i)
        if(bits[i])
            ++ count;
    return count;
}

#endif

#pragma mark - Integer Points

NS_INLINE BAPoint2 BAPoint2Make( NSInteger x, NSInteger y ) {
    return (BAPoint2) { x, y };
}

NS_INLINE BAPoint2 BAPoint2Zero( void ) {
    return (BAPoint2) { 0, 0 };
}

NS_INLINE BOOL BAPoint2EqualToPoint2( BAPoint2 point1, BAPoint2 point2 ) {
    return point1.x == point2.x && point1.y == point2.y;
}

NS_INLINE BAQuadrant BAPoint2GetQuadrant (BAPoint2 point ) {
    BAQuadrant q = BAQuadrant00;
    if (point.x < 0) {
        q <<= 1;
    }
    if (point.y < 0) {
        q <<= 2;
    }
    return q;
}

#pragma mark - Integer Sizes

NS_INLINE BASize2 BASize2Make( NSInteger w, NSInteger h ) {
    return (BASize2) { w, h };
}

NS_INLINE BASize2 BASize2Zero( void ) {
    return (BASize2) { 0, 0 };
}

NS_INLINE BOOL BASize2EqualToSize2( BASize2 size1, BASize2 size2 ) {
    return size1.width == size2.width && size1.height == size2.height;
}

#pragma mark - Integer Regions

NS_INLINE BARegion2 BARegion2Make(NSInteger x, NSInteger y, NSInteger width, NSInteger height) {
    return (BARegion2) { { x, y }, { width, height } };
};

NS_INLINE BARegion2 BARegion2Zero( void ) {
    return (BARegion2) { 0, 0 };
};

NS_INLINE BOOL BARegion2EqualToRegion2(BARegion2 region1, BARegion2 region2) {
    return BAPoint2EqualToPoint2(region1.origin, region2.origin) && BASize2EqualToSize2(region1.size, region2.size);
}

NS_INLINE BAPoint2 BARegion2GetOrigin(BARegion2 region) {
    return region.origin;
}

NS_INLINE BASize2 BARegion2GetSize(BARegion2 region) {
    return region.size;
}

NS_INLINE NSInteger BARegion2GetWidth(BARegion2 region) {
    return region.size.width;
}

NS_INLINE NSInteger BARegion2GetHeight(BARegion2 region) {
    return region.size.height;
}

NS_INLINE NSInteger BARegion2Area(BARegion2 region) {
    return region.size.width * region.size.height;
}

NS_INLINE NSInteger BARegion2GetMinX(BARegion2 region) {
    return region.origin.x;
}

NS_INLINE NSInteger BARegion2GetMaxX(BARegion2 region) {
    return region.origin.x + region.size.width;
}

NS_INLINE NSInteger BARegion2GetMinY(BARegion2 region) {
    return region.origin.y;
}

NS_INLINE NSInteger BARegion2GetMaxY(BARegion2 region) {
    return region.origin.y + region.size.height;
}

NS_INLINE BAPoint2 BARegion2GetBottomLeft(BARegion2 region) {
    return BAPoint2Make(BARegion2GetMinX(region), BARegion2GetMinY(region));
}

NS_INLINE BAPoint2 BARegion2GetBottomRight(BARegion2 region) {
    return BAPoint2Make(BARegion2GetMaxX(region), BARegion2GetMinY(region));
}

NS_INLINE BAPoint2 BARegion2GetTopLeft(BARegion2 region) {
    return BAPoint2Make(BARegion2GetMinX(region), BARegion2GetMaxY(region));
}

NS_INLINE BAPoint2 BARegion2GetTopRight(BARegion2 region) {
    return BAPoint2Make(BARegion2GetMaxX(region), BARegion2GetMaxY(region));
}

NS_INLINE BOOL BARegion2IsEmpty(BARegion2 region) {
    return region.size.width <= 0 || region.size.height <= 0;
}

NS_INLINE BAQuadrant BARegion2GetQuadrant(BARegion2 region) {
    BAQuadrant qbl = BAPoint2GetQuadrant(BARegion2GetBottomLeft(region));
    BAQuadrant qbr = BAPoint2GetQuadrant(BARegion2GetBottomRight(region));
    BAQuadrant qtl = BAPoint2GetQuadrant(BARegion2GetTopLeft(region));
    BAQuadrant qtr = BAPoint2GetQuadrant(BARegion2GetTopRight(region));
    
    return qbl | qbr | qtl | qtr;
}

NS_INLINE BOOL BARegion2ContainsRegion2(BARegion2 outer, BARegion2 inner) {
    return (BARegion2GetMinX(outer) <= BARegion2GetMinX(inner) &&
            BARegion2GetMaxX(outer) >= BARegion2GetMaxX(inner) &&
            BARegion2GetMinY(outer) <= BARegion2GetMinY(inner) &&
            BARegion2GetMaxY(outer) >= BARegion2GetMaxY(inner));
}

NS_INLINE BARegion2 BARegion2Intersection(BARegion2 first, BARegion2 second) {
    BAPoint2 bottomLeft = BAPoint2Make(MAX(BARegion2GetMinX(first), BARegion2GetMinX(second)), MAX(BARegion2GetMinY(first), BARegion2GetMinY(second)));
    BAPoint2 topRight = BAPoint2Make(MIN(BARegion2GetMaxX(first), BARegion2GetMaxX(second)), MIN(BARegion2GetMaxY(first), BARegion2GetMaxY(second)));
    BASize2 size = BASize2Make(topRight.x - bottomLeft.x, topRight.y - bottomLeft.y);
    return BARegion2Make(bottomLeft.x, bottomLeft.y, size.width, size.height);
}

NS_INLINE CGRect BARegion2ToCGRect(BARegion2 region) {
    return CGRectMake(BARegion2GetMinX(region), BARegion2GetMinY(region), BARegion2GetWidth(region), BARegion2GetHeight(region));
}

NS_INLINE BARegion2 BARegion2FromCGRect(CGRect rect) {
    return BARegion2Make(CGRectGetMinX(rect), CGRectGetMinY(rect), CGRectGetWidth(rect), CGRectGetHeight(rect));
}
