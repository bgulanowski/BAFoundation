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
- (void)iterateRegion:(BANoiseRegion)region block:(BANoiseIteratorBlock)block increment:(double)inc;
- (void)iterateRegion:(BANoiseRegion)region block:(BANoiseIteratorBlock)block;

@end

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

- (instancetype)initWithSeed:(NSUInteger)seed octaves:(NSUInteger)octaves persistence:(double)persistence transform:(BANoiseTransform *)transform;

- (BOOL)isEqualToNoise:(BANoise *)other;
// copies share underlying (immutable) noise data
- (BANoise *)copyWithOctaves:(NSUInteger)octaves persistence:(double)persistence transform:(BANoiseTransform *)transform;
+ (BANoise *)noiseWithSeed:(NSUInteger)seed octaves:(NSUInteger)octaves persistence:(double)persistence transform:(BANoiseTransform *)transform;
+ (BANoise *)randomNoise;

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


@interface BASampleArray (BANoiseInitializing)
- (void)fillWithNoise:(id<BANoise>)noise increment:(double)increment;
@end
