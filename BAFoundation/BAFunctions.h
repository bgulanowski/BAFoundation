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

NS_INLINE BARegion BARegionMake(NSInteger x, NSInteger y, NSInteger width, NSInteger height) {
    return (BARegion) { { x, y }, { width, height } };
};

NS_INLINE BARegion BARegionZero( void ) {
    return (BARegion) { 0, 0 };
};

NS_INLINE BOOL BARegionEqualToRegion(BARegion region1, BARegion region2) {
    return BAPoint2EqualToPoint2(region1.origin, region2.origin) && BASize2EqualToSize2(region1.size, region2.size);
}

NS_INLINE BAPoint2 BARegionGetOrigin(BARegion region) {
    return region.origin;
}

NS_INLINE BASize2 BARegionGetSize(BARegion region) {
    return region.size;
}

NS_INLINE NSInteger BARegionGetWidth(BARegion region) {
    return region.size.width;
}

NS_INLINE NSInteger BARegionGetHeight(BARegion region) {
    return region.size.height;
}

NS_INLINE NSInteger BARegionArea(BARegion region) {
    return region.size.width * region.size.height;
}

NS_INLINE NSInteger BARegionGetMinX(BARegion region) {
    return region.origin.x;
}

NS_INLINE NSInteger BARegionGetMaxX(BARegion region) {
    return region.origin.x + region.size.width;
}

NS_INLINE NSInteger BARegionGetMinY(BARegion region) {
    return region.origin.y;
}

NS_INLINE NSInteger BARegionGetMaxY(BARegion region) {
    return region.origin.y + region.size.height;
}

NS_INLINE BAPoint2 BARegionGetBottomLeft(BARegion region) {
    return BAPoint2Make(BARegionGetMinX(region), BARegionGetMinY(region));
}

NS_INLINE BAPoint2 BARegionGetBottomRight(BARegion region) {
    return BAPoint2Make(BARegionGetMaxX(region), BARegionGetMinY(region));
}

NS_INLINE BAPoint2 BARegionGetTopLeft(BARegion region) {
    return BAPoint2Make(BARegionGetMinX(region), BARegionGetMaxY(region));
}

NS_INLINE BAPoint2 BARegionGetTopRight(BARegion region) {
    return BAPoint2Make(BARegionGetMaxX(region), BARegionGetMaxY(region));
}

NS_INLINE BOOL BARegionIsEmpty(BARegion region) {
    return region.size.width <= 0 || region.size.height <= 0;
}

NS_INLINE BAQuadrant BARegionGetQuadrant(BARegion region) {
    BAQuadrant qbl = BAPoint2GetQuadrant(BARegionGetBottomLeft(region));
    BAQuadrant qbr = BAPoint2GetQuadrant(BARegionGetBottomRight(region));
    BAQuadrant qtl = BAPoint2GetQuadrant(BARegionGetTopLeft(region));
    BAQuadrant qtr = BAPoint2GetQuadrant(BARegionGetTopRight(region));
    
    return qbl | qbr | qtl | qtr;
}

NS_INLINE BOOL BARegionContainsRegion(BARegion outer, BARegion inner) {
    return (BARegionGetMinX(outer) <= BARegionGetMinX(inner) &&
            BARegionGetMaxX(outer) >= BARegionGetMaxX(inner) &&
            BARegionGetMinY(outer) <= BARegionGetMinY(inner) &&
            BARegionGetMaxY(outer) >= BARegionGetMaxY(inner));
}

NS_INLINE BARegion BARegionIntersection(BARegion first, BARegion second) {
    BAPoint2 bottomLeft = BAPoint2Make(MAX(BARegionGetMinX(first), BARegionGetMinX(second)), MAX(BARegionGetMinY(first), BARegionGetMinY(second)));
    BAPoint2 topRight = BAPoint2Make(MIN(BARegionGetMaxX(first), BARegionGetMaxX(second)), MIN(BARegionGetMaxY(first), BARegionGetMaxY(second)));
    BASize2 size = BASize2Make(topRight.x - bottomLeft.x, topRight.y - bottomLeft.y);
    return BARegionMake(bottomLeft.x, bottomLeft.y, size.width, size.height);
}

NS_INLINE CGRect BARegionToCGRect(BARegion region) {
    return CGRectMake(BARegionGetMinX(region), BARegionGetMinY(region), BARegionGetWidth(region), BARegionGetHeight(region));
}

NS_INLINE BARegion BARegionFromCGRect(CGRect rect) {
    return BARegionMake(CGRectGetMinX(rect), CGRectGetMinY(rect), CGRectGetWidth(rect), CGRectGetHeight(rect));
}
