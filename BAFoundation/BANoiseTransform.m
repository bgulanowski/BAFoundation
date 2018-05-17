//
//  BANoiseTransform.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 2018-05-16.
//  Copyright © 2018 Lichen Labs. All rights reserved.
//

#import "BANoiseTransform.h"

NS_INLINE BOOL equalMatrices(double m1[16], double m2[16]) {
    for (NSUInteger i=0; i<16; ++i)
        if(m1[i] != m2[i]) return NO;
    return YES;
}

NS_INLINE void makeLinearTransformationMatrix(double *m, BANoiseVector s, BANoiseVector a, double angle) {
    
    BANoiseVector nv = BANormalizeNoiseVector(a);
    
    double u = nv.x, v = nv.y, w = nv.z;
    double uu = u*u, vv = v*v, ww = w*w, uv = u*v, uw = u*w, vw = v*w;
    double cosa = cos(angle), ccosa = 1-cosa, sina = sin(angle);
    double usina = u*sina, vsina = v*sina, wsina = w*sina, uvccosa = uv*ccosa, uwccosa = uw*ccosa, vwccosa = vw*ccosa;
    
    m[ 0] = s.x * (cosa + uu*ccosa);
    m[ 1] =         uvccosa - wsina;
    m[ 2] =         uwccosa + vsina;
    m[ 3] = 0;
    
    m[ 4] =         uvccosa + wsina;
    m[ 5] = s.y * (cosa + vv*ccosa);
    m[ 6] =         vwccosa - usina;
    m[ 7] = 0;
    
    m[ 8] =          uwccosa - vsina;
    m[ 9] =          vwccosa + usina;
    m[10] = s.z * (cosa + ww*ccosa);
    m[11] = 0;
    
    m[12] = 0;
    m[13] = 0;
    m[14] = 0;
    m[15] = 1.;
}

NS_INLINE void makeTranslationMatrix(double *m, BANoiseVector t) {
    m[ 0] = 1.;
    m[ 1] = 0;
    m[ 2] = 0;
    m[ 3] = 0;
    
    m[ 4] = 0;
    m[ 5] = 1.;
    m[ 6] = 0;
    m[ 7] = 0;
    
    m[ 8] = 0;
    m[ 9] = 0;
    m[10] = 1.;
    m[11] = 0;
    
    m[12] = t.x;
    m[13] = t.y;
    m[14] = t.z;
    m[15] = 1.;
}

NS_INLINE void makeScaleMatrix(double m[16], BANoiseVector s) {
    m[ 0] = s.x;
    m[ 1] = 0;
    m[ 2] = 0;
    m[ 3] = 0;
    
    m[ 4] = 0;
    m[ 5] = s.y;
    m[ 6] = 0;
    m[ 7] = 0;
    
    m[ 8] = 0;
    m[ 9] = 0;
    m[10] = s.z;
    m[11] = 0;
    
    m[12] = 0;
    m[13] = 0;
    m[14] = 0;
    m[15] = 1.;
}

/*
 static inline void makeIdentityMatrix(double *m) {
 m[ 0] = 1.;
 m[ 1] = 0;
 m[ 2] = 0;
 m[ 3] = 0;
 
 m[ 4] = 0;
 m[ 5] = 1.;
 m[ 6] = 0;
 m[ 7] = 0;
 
 m[ 8] = 0;
 m[ 9] = 0;
 m[10] = 1.;
 m[11] = 0;
 
 m[12] = 0;
 m[13] = 0;
 m[14] = 0;
 m[15] = 1.;
 }
 */

static BANoiseVector transformVector(BANoiseVector vector, double *matrix) {
    
    BANoiseVector r;
    
    r.x = vector.x * matrix[0] + vector.y * matrix[4] + vector.z * matrix[8];
    r.y = vector.x * matrix[1] + vector.y * matrix[5] + vector.z * matrix[9];
    r.z = vector.x * matrix[2] + vector.y * matrix[6] + vector.z * matrix[10];
    
    return r;
}

@implementation BANoiseTransform

@synthesize scale=_scale, rotationAxis=_rotationAxis, rotationAngle=_rotationAngle, translation=_translation;

- (double *)matrix {
    return _matrix;
}

- (BOOL)isEqualToTransform:(BANoiseTransform *)transform {
    return equalMatrices(_matrix, transform->_matrix);
}

- (id)initWithMatrix:(double *)matrix {
    self = [self init];
    if(self) {
        for (NSUInteger i=0; i<16; ++i)
            _matrix[i] = matrix[i];
    }
    return self;
}

- (id)initWithScale:(BANoiseVector)scale rotationAxis:(BANoiseVector)axis angle:(double)angle {
    double m[16];
    makeLinearTransformationMatrix(m, scale, axis, angle);
    self = [self initWithMatrix:m];
    if(self) {
        _scale = scale;
        _rotationAxis = axis;
        _rotationAngle = angle;
    }
    return self;
}

- (id)initWithScale:(BANoiseVector)scale {
    double m[16];
    makeScaleMatrix(m, scale);
    self = [self initWithMatrix:m];
    if(self) {
        _scale = scale;
    }
    return self;
}

- (id)initWithRotationAxis:(BANoiseVector)axis angle:(double)angle {
    return [self initWithScale:BANoiseVectorMake(1., 1., 1.) rotationAxis:axis angle:angle];
}

- (id)initWithTranslation:(BANoiseVector)translation {
    double m[16];
    makeTranslationMatrix(m, translation);
    self = [self initWithMatrix:m];
    if(self) {
        _translation = translation;
    }
    return self;
}

+ (instancetype)randomTranslation {
    return [[[self alloc] initWithTranslation:BARandomNoiseVector()] autorelease];
}

+ (instancetype)randomRotation {
    return [[[self alloc] initWithRotationAxis:BARandomNoiseVector() angle:BARandomCGFloatInRange(-M_PI, M_PI)] autorelease];
}

+ (instancetype)randomScale {
    return [[[self alloc] initWithScale:BARandomNoiseVector()] autorelease];
}

+ (instancetype)randomTransform {
    
    int indices[3] = { 0, 1, 2 };
    for (int i = 0; i < 3; ++i) {
        int a = (i + (int)BARandomCGFloatInRange(0.0, 4.0))%3;
        int t = indices[i];
        indices[i] = indices[a];
        indices[a] = t;
    }
    
    BANoiseTransform *x[3];
    x[indices[0]] = [BANoiseTransform randomTranslation];
    x[indices[1]] = [BANoiseTransform randomRotation];
    x[indices[2]] = [BANoiseTransform randomScale];
    
    BANoiseTransform *t = x[0];
    t = [t transformByPremultiplyingTransform:x[1]];
    return [t transformByPremultiplyingTransform:x[2]];
}

- (BANoiseTransform *)transformByPremultiplyingTransform:(BANoiseTransform *)transform {
    
    double r[16];
    double *t = transform->_matrix;
    double *m = _matrix;
    
    r[ 0] = t[ 0] * m[ 0] + t[ 4] * m[ 1] + t[ 8] * m[ 2] + t[12] * m[ 3];
    r[ 1] = t[ 1] * m[ 0] + t[ 5] * m[ 1] + t[ 9] * m[ 2] + t[13] * m[ 3];
    r[ 2] = t[ 2] * m[ 0] + t[ 6] * m[ 1] + t[10] * m[ 2] + t[14] * m[ 3];
    r[ 3] = t[ 3] * m[ 0] + t[ 7] * m[ 1] + t[11] * m[ 2] + t[15] * m[ 3];
    
    r[ 4] = t[ 0] * m[ 4] + t[ 4] * m[ 5] + t[ 8] * m[ 6] + t[12] * m[ 7];
    r[ 5] = t[ 1] * m[ 4] + t[ 5] * m[ 5] + t[ 9] * m[ 6] + t[13] * m[ 7];
    r[ 6] = t[ 2] * m[ 4] + t[ 6] * m[ 5] + t[10] * m[ 6] + t[14] * m[ 7];
    r[ 7] = t[ 3] * m[ 4] + t[ 7] * m[ 5] + t[11] * m[ 6] + t[15] * m[ 7];
    
    r[ 8] = t[ 0] * m[ 8] + t[ 4] * m[ 9] + t[ 8] * m[10] + t[12] * m[11];
    r[ 9] = t[ 1] * m[ 8] + t[ 5] * m[ 9] + t[ 9] * m[10] + t[13] * m[11];
    r[10] = t[ 2] * m[ 8] + t[ 6] * m[ 9] + t[10] * m[10] + t[14] * m[11];
    r[11] = t[ 3] * m[ 8] + t[ 7] * m[ 9] + t[11] * m[10] + t[15] * m[11];
    
    r[12] = t[ 0] * m[12] + t[ 4] * m[13] + t[ 8] * m[14] + t[12] * m[15];
    r[13] = t[ 1] * m[12] + t[ 5] * m[13] + t[ 9] * m[14] + t[13] * m[15];
    r[14] = t[ 2] * m[12] + t[ 6] * m[13] + t[10] * m[14] + t[14] * m[15];
    r[15] = t[ 3] * m[12] + t[ 7] * m[13] + t[11] * m[14] + t[15] * m[15];
    
    return [[[[self class] alloc] initWithMatrix:r] autorelease];
}

- (BANoiseVector)transformVector:(BANoiseVector)vector {
    return transformVector(vector, _matrix);
}

- (BAVectorTransformer)transformer {
    return [^(BANoiseVector vector) { return transformVector(vector, _matrix); } copy];
}

@end
