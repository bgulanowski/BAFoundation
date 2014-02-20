//
//  BANoise.h
//  BAFoundation
//
//  Created by Brent Gulanowski on 2013-07-12.
//  Copyright (c) 2013 Lichen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <BAFoundation/BABitArray.h>


typedef struct {
    double x;
    double y;
    double z;
} BANoiseVector;


extern inline BANoiseVector BANoiseVectorMake(double x, double y, double z);


typedef struct {
    BANoiseVector origin;
    BANoiseVector size;
} BANoiseRegion;


extern inline BANoiseRegion BANoiseRangeMake(BANoiseVector o, BANoiseVector s);

typedef BANoiseVector (^BAVectorTransformer)(BANoiseVector vector);
typedef double (^BANoiseEvaluator)(double x, double y, double z);
typedef BOOL (^BANoiseIteratorBlock)(BANoiseVector position, double value);


@interface BANoiseTransform : NSObject {
@private
    BANoiseVector _scale;
    BANoiseVector _rotationAxis;
    BANoiseVector _translation;
    double _rotationAngle;
    double _matrix[16];
}

// These are only available if they were provided at instantiation
@property (nonatomic, readonly) BANoiseVector scale;
@property (nonatomic, readonly) BANoiseVector rotationAxis;
@property (nonatomic, readonly) BANoiseVector translation;
@property (nonatomic, readonly) double rotationAngle;

- (BOOL)isEqualToTransform:(BANoiseTransform *)transform;

- (id)initWithMatrix:(double[16])matrix;
// Rotations are about the origin
- (id)initWithScale:(BANoiseVector)scale rotationAxis:(BANoiseVector)axis angle:(double)angle;
- (id)initWithScale:(BANoiseVector)scale;
- (id)initWithRotationAxis:(BANoiseVector)axis angle:(double)angle;
- (id)initWithTranslation:(BANoiseVector)translation;

- (BANoiseTransform *)transformByPremultiplyingTransform:(BANoiseTransform *)transform;

- (BANoiseVector)transformVector:(BANoiseVector)vector;
- (BAVectorTransformer)transformer;

@end


@protocol BANoise <NSObject, NSCoding, NSCopying>

// Returns a value in [-1.0,1.0]
- (double)evaluateX:(double)x Y:(double)y Z:(double)z;
@optional
- (BANoiseEvaluator)evaluator;
- (void)iterateRange:(BANoiseRegion)range block:(BANoiseIteratorBlock)block;

@end


extern double BANoiseEvaluate(const int *p, double x, double y, double z);
extern double BANoiseBlend(const int *p, double x, double y, double z, double octave_count, double persistence);

extern double BASimplexNoise2DEvaluate(const int *p, const int *pmod, double xin, double  yin);
extern double BASimplexNoise3DEvaluate(const int *p, const int *pmod, double xin, double  yin, double zin);
extern double BASimplexNoise3DBlend(const int *p, const int *pmod, double x, double y, double z, double octave_count, double persistence);

extern const int BADefaultPermutation[512];


@interface BANoise : NSObject<BANoise> {
    BANoiseTransform *_transform;
    NSData *_data;
    unsigned long _seed;
    NSUInteger _octaves;
    double _persistence;
}

@property (nonatomic, readonly) BANoiseTransform *transform;

@property (nonatomic, readonly) unsigned long seed;
@property (nonatomic, readonly) NSUInteger octaves;
@property (nonatomic, readonly) double persistence;

- (BOOL)isEqualToNoise:(BANoise *)other;
// copies share underlying (immutable) noise data
- (BANoise *)copyWithOctaves:(NSUInteger)octaves persistence:(double)persistence transform:(BANoiseTransform *)transform;
+ (BANoise *)noiseWithSeed:(unsigned long)seed octaves:(NSUInteger)octaves persistence:(double)persistence transform:(BANoiseTransform *)transform;

@end


@interface BASimplexNoise : BANoise {
	NSData *_mod;
}

@end


@interface BABlendedNoise : NSObject<BANoise> {
    NSArray *_noises;
    NSArray *_ratios;
	NSUInteger _count;
}

@property (nonatomic, readonly) NSArray *noises;
@property (nonatomic, readonly) NSArray *ratios; // nsnumber doubles from (0, 1]

- (instancetype)initWithNoises:(NSArray *)noises ratios:(NSArray *)ratios;
+ (BABlendedNoise *)blendedNoiseWithNoises:(NSArray *)noises ratios:(NSArray *)ratios;

@end


@interface NSData (BANoise)

- (id)initWithSeed:(unsigned)seed;
- (NSData *)noiseModulusData;
+ (NSData *)noiseDataWithSeed:(unsigned)seed;
+ (NSData *)defaultNoiseData;
+ (NSData *)randomNoiseData;

@end


@interface BABitArray (BANoiseInitializing)
- (id)initWithSize:(CGSize)size noise:(id<BANoise>)noise min:(double)min max:(double)max;
+ (BABitArray *)bitArrayWithSize:(CGSize)size noise:(id<BANoise>)noise min:(double)min max:(double)max;
@end
