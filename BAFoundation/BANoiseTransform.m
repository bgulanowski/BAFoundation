//
//  BANoiseTransform.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 2018-05-16.
//  Copyright © 2018 Lichen Labs. All rights reserved.
//

#import "BANoiseTransform.h"
#import "BANoiseFunctions.h"
#import "NSObject+BAIntrospection.h"

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

NS_INLINE void matrixConcatenate(double m[16], double a[16], double b[16]) {
    
    m[ 0] = a[ 0] * b[ 0] + a[ 4] * b[ 1] + a[ 8] * b[ 2] + a[12] * b[ 3];
    m[ 1] = a[ 1] * b[ 0] + a[ 5] * b[ 1] + a[ 9] * b[ 2] + a[13] * b[ 3];
    m[ 2] = a[ 2] * b[ 0] + a[ 6] * b[ 1] + a[10] * b[ 2] + a[14] * b[ 3];
    m[ 3] = a[ 3] * b[ 0] + a[ 7] * b[ 1] + a[11] * b[ 2] + a[15] * b[ 3];
    
    m[ 4] = a[ 0] * b[ 4] + a[ 4] * b[ 5] + a[ 8] * b[ 6] + a[12] * b[ 7];
    m[ 5] = a[ 1] * b[ 4] + a[ 5] * b[ 5] + a[ 9] * b[ 6] + a[13] * b[ 7];
    m[ 6] = a[ 2] * b[ 4] + a[ 6] * b[ 5] + a[10] * b[ 6] + a[14] * b[ 7];
    m[ 7] = a[ 3] * b[ 4] + a[ 7] * b[ 5] + a[11] * b[ 6] + a[15] * b[ 7];
    
    m[ 8] = a[ 0] * b[ 8] + a[ 4] * b[ 9] + a[ 8] * b[10] + a[12] * b[11];
    m[ 9] = a[ 1] * b[ 8] + a[ 5] * b[ 9] + a[ 9] * b[10] + a[13] * b[11];
    m[10] = a[ 2] * b[ 8] + a[ 6] * b[ 9] + a[10] * b[10] + a[14] * b[11];
    m[11] = a[ 3] * b[ 8] + a[ 7] * b[ 9] + a[11] * b[10] + a[15] * b[11];
    
    m[12] = a[ 0] * b[12] + a[ 4] * b[13] + a[ 8] * b[14] + a[12] * b[15];
    m[13] = a[ 1] * b[12] + a[ 5] * b[13] + a[ 9] * b[14] + a[13] * b[15];
    m[14] = a[ 2] * b[12] + a[ 6] * b[13] + a[10] * b[14] + a[14] * b[15];
    m[15] = a[ 3] * b[12] + a[ 7] * b[13] + a[11] * b[14] + a[15] * b[15];
}

static BANoiseVector transformVector(BANoiseVector vector, double *matrix) {
    
    BANoiseVector r;
    
    r.x = vector.x * matrix[0] + vector.y * matrix[4] + vector.z * matrix[8] + matrix[12];
    r.y = vector.x * matrix[1] + vector.y * matrix[5] + vector.z * matrix[9] + matrix[13];
    r.z = vector.x * matrix[2] + vector.y * matrix[6] + vector.z * matrix[10] + matrix[14];
    
    return r;
}

@implementation BANoiseTransform

@synthesize scale=_scale, rotationAxis=_rotationAxis, rotationAngle=_rotationAngle, translation=_translation;

- (NSUInteger)hash {
    return BAHash((char *)_matrix, 16);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSKeyedArchiver *)aDecoder {
    NSData *matrixData = [aDecoder decodeObjectForKey:SelKey(matrix)];
    self = [self initWithMatrix:(double *)[matrixData bytes]];
    if (self) {
        NSValue *t = [aDecoder decodeObjectForKey:SelKey(translation)];
        NSValue *s = [aDecoder decodeObjectForKey:SelKey(scale)];
        NSValue *r = [aDecoder decodeObjectForKey:SelKey(rotationAxis)];
        _translation = [t noiseVector];
        _scale = [s noiseVector];
        _rotationAxis = [r noiseVector];
        _rotationAngle = [aDecoder decodeDoubleForKey:SelKey(rotationAngle)];
    }
    return self;
}

- (void)encodeWithCoder:(NSKeyedArchiver *)aCoder {
    [aCoder encodeObject:[NSData dataWithBytes:_matrix length:sizeof(double)*16] forKey:SelKey(matrix)];
    NSString *key = nil;
    BANoiseVector *vector = NULL;
    if (!BANoiseVectorIsZero(_translation)) {
        vector = &_translation;
        key = SelKey(translation);
    }
    else if(!BANoiseVectorIsZero(_scale)) {
        vector = &_scale;
    }
    else if (_rotationAngle != 0.0) {
        vector = &_rotationAxis;
        [aCoder encodeDouble:_rotationAngle forKey:SelKey(rotationAngle)];
    }
    if (key) {
        [aCoder encodeObject:[NSValue valueWithNoiseVector:*vector] forKey:key];
    }
}

#pragma mark - BANoiseTransform

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
    return [[[self alloc] initWithRotationAxis:BARandomNoiseVector() angle:BARandomCGFloatInRange((CGFloat)-M_PI, (CGFloat)M_PI)] autorelease];
}

+ (instancetype)randomScale {
    return [[[self alloc] initWithScale:BARandomNoiseVector()] autorelease];
}

+ (instancetype)randomTransform {
    
    double l[16];
    double t[16];
    double m[16];
    
    makeLinearTransformationMatrix(l, BARandomNoiseVector(), BARandomNoiseVector(), BARandomCGFloatInRange((CGFloat)-M_PI, (CGFloat)M_PI));
    makeTranslationMatrix(t, BARandomNoiseVector());
    matrixConcatenate(m, l, t);
    
    return [[[self alloc] initWithMatrix:m] autorelease];
}

- (BANoiseTransform *)transformByPremultiplyingTransform:(BANoiseTransform *)transform {
    double r[16];
    matrixConcatenate(r, transform->_matrix, _matrix);
    return [[[[self class] alloc] initWithMatrix:r] autorelease];
}

- (BANoiseVector)transformVector:(BANoiseVector)vector {
    return transformVector(vector, _matrix);
}

- (BAVectorTransformer)transformer {
    return [^(BANoiseVector vector) { return transformVector(vector, _matrix); } copy];
}

@end
