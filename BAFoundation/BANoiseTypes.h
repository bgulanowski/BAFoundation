//
//  BANoiseTypes.h
//  BAFoundation
//
//  Created by Brent Gulanowski on 2018-05-16.
//  Copyright © 2018 Lichen Labs. All rights reserved.
//

#import <BAFoundation/BAMacros.h>
#import <BAFoundation/BAFunctions.h>

typedef struct {
    double x;
    double y;
    double z;
} BANoiseVector;

#define BANoiseVectorZero ((BANoiseVector){ 0, 0, 0 })

NS_INLINE BANoiseVector BANoiseVectorMake(double x, double y, double z) {
    return (BANoiseVector){ x, y, z };
}

NS_INLINE BOOL BANoiseVectorsEqual(BANoiseVector v1, BANoiseVector v2) {
    return BAEQ(v1.x, v2.x) && BAEQ(v1.y, v2.y) && BAEQ(v1.z, v2.z);
}

NS_INLINE BOOL BANoiseVectorIsZero(BANoiseVector v) {
    return BANoiseVectorsEqual(v, BANoiseVectorZero);
}

NS_INLINE BANoiseVector BARandomNoiseVector( void ) {
    CGFloat x = BARandomCGFloat();
    CGFloat y = BARandomCGFloat();
    CGFloat z = BARandomCGFloat();
    return BANoiseVectorMake(x, y, z);
}

typedef struct {
    BANoiseVector origin;
    BANoiseVector size;
} BANoiseRegion;

NS_INLINE BANoiseRegion BANoiseRegionMake(BANoiseVector o, BANoiseVector s) {
    return (BANoiseRegion){o,s};
}


NS_INLINE double BANoiseVectorLength(BANoiseVector v) {
    return sqrt(v.x*v.x + v.y*v.y + v.z*v.z);
}

NS_INLINE BANoiseVector BANormalizeNoiseVector(BANoiseVector v) {
    
    BANoiseVector r = {};
    double length = BANoiseVectorLength(v);
    
    if(length) {
        r.x = v.x/length;
        r.y = v.y/length;
        r.z = v.z/length;
    }
    
    return r;
}

typedef BANoiseVector (^BAVectorTransformer)(BANoiseVector vector);
typedef double (^BANoiseEvaluator)(double x, double y, double z);
typedef BOOL (^BANoiseIteratorBlock)(double x, double y, double z, double value);
