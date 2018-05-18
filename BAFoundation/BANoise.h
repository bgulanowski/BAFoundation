//
//  BANoise.h
//  BAFoundation
//
//  Created by Brent Gulanowski on 2013-07-12.
//  Copyright (c) 2013 Lichen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <BAFoundation/BABitArray.h>
#import <BAFoundation/BASampleArray.h>
#import <BAFoundation/BANoiseTypes.h>
#import <BAFoundation/BANoiseTransform.h>

@protocol BANoise <NSObject, NSCoding, NSCopying>

// Returns a value in [-1.0,1.0]
- (double)evaluateX:(double)x Y:(double)y Z:(double)z;
@optional
- (BANoiseEvaluator)evaluator;
- (void)iterateRegion:(BANoiseRegion)region block:(BANoiseIteratorBlock)block;

@end

@interface BANoise : NSObject<BANoise> {
    BANoiseTransform *_transform;
    NSData *_data;
    NSUInteger _seed;
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
+ (BANoise *)noiseWithSeed:(NSUInteger)seed octaves:(NSUInteger)octaves persistence:(double)persistence transform:(BANoiseTransform *)transform;
+ (BANoise *)randomNoise;

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

- (id)initWithSeed:(NSUInteger)seed;
- (NSData *)noiseModulusData;
+ (NSData *)noiseDataWithSeed:(NSUInteger)seed;
+ (NSData *)defaultNoiseData;
+ (NSData *)randomNoiseData;

@end


@interface BABitArray (BANoiseInitializing)
- (id)initWithSize2:(BASize2)size noise:(id<BANoise>)noise min:(double)min max:(double)max;
+ (BABitArray *)bitArrayWithSize2:(BASize2)size noise:(id<BANoise>)noise min:(double)min max:(double)max;
@end
