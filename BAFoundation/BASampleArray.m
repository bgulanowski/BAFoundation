//
//  BASampleArray.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 12-04-22.
//  Copyright (c) 2012 Lichen Labs. All rights reserved.
//

#import "BASampleArray.h"


#pragma mark -
@implementation BASampleArray

#pragma mark - Properties
@dynamic samples, count;
@synthesize power=_power, order=_order, size=_size;


#pragma mark - Accessors

- (UInt8 *)samples {
    return _samples;
}

- (NSUInteger)count {
    return (NSUInteger)pow(_order, _power);
}


#pragma mark - NSObject
- (void)dealloc {
    if(_samples) free(_samples);
    [super dealloc];
}


#pragma mark - BASampleArray
- (id)initWithPower:(NSUInteger)power order:(NSUInteger)order size:(NSUInteger)size {
    self = [super init];
    if(self) {
        size_t sampleSize = size * (NSUInteger)powf(order, power);
        _power = power;
        _order = order;
        _size = size;
        _samples = malloc(sampleSize);
        NSAssert(_samples, @"Failed to allocate memory for BASampleArray");
    }
    return self;
}

- (void)sample:(UInt8 *)sample atIndex:(NSUInteger)index {
    strncpy((char *)sample+index*_size, (char *)sample, _size);
//    UInt8 *base = sample+index*_size;
//    
//    for (NSUInteger i=0; i<_size; ++i)
//        sample[i] = base[i];
}

- (void)setSample:(UInt8 *)sample atIndex:(NSUInteger)index {
    strncpy((char *)sample, (char *)sample+index*_size, _size);

//    UInt8 *base = _samples+index*_size;
//    
//    for(NSUInteger i=0; i<_size; ++i)
//        base[i] = sample[i];
}

static inline NSUInteger indexForCoordinates(NSUInteger *coordinates, NSUInteger power) {
    
    NSUInteger sampleIndex = 0;
    NSUInteger factor = 1;
    
    for(NSUInteger i=0; i<power; ++i) {
        sampleIndex += coordinates[i] * factor++;
    }
    
    return sampleIndex;
}

- (void)sample:(UInt8 *)sample atCoordinates:(NSUInteger *)coordinates {
     [self sample:sample atIndex:indexForCoordinates(coordinates, _power)];
}

- (void)setSample:(UInt8 *)sample atCoordinates:(NSUInteger *)coordinates {
    [self setSample:sample atIndex:indexForCoordinates(coordinates, _power)];
}

- (UInt32)pageSampleAtX:(NSUInteger)x y:(NSUInteger)y {
    UInt32 *p = (UInt32 *)_samples;
    return p[x+y*32];
}

- (void)setPageSample:(UInt32)sample atX:(NSUInteger)x y:(NSUInteger)y {
    UInt32 *p = (UInt32 *)_samples;
    p[x+y*32] = sample;
}

- (UInt32)blockSampleAtX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z {
    UInt32 *p = (UInt32 *)_samples;
    return p[x+y*32+z*1024];
}

- (void)setBlockSample:(UInt32)sample atX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z {
    UInt32 *p = (UInt32 *)_samples;
    p[x+y*32+z*1024] = sample;
}

- (float)pageFloatAtX:(NSUInteger)x y:(NSUInteger)y {
    float *p = (float *)_samples;
    return p[x+y*32];
}

- (void)setPageFloat:(float)sample atX:(NSUInteger)x y:(NSUInteger)y {
    float *p = (float *)_samples;
    p[x+y*32] = sample;
}

- (float)blockFloatAtX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z {
    float *p = (float *)_samples;
    return p[x+y*32+z*1024];
}

- (void)setBlockFloat:(float)sample  atX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z {
    float *p = (float *)_samples;
    p[x+y*32+z*1024] = sample;
}


#pragma mark - Factories
+ (BASampleArray *)sampleArrayWithPower:(NSUInteger)power order:(NSUInteger)order size:(NSUInteger)size {
    return (BASampleArray *)[[[self alloc] initWithPower:power order:order size:size] autorelease];
}

+ (BASampleArray *)page {
    return (BASampleArray *)[[[self alloc] initWithPower:2 order:32 size:4] autorelease];
}

+(BASampleArray *)block {
    return (BASampleArray *)[[[self alloc] initWithPower:3 order:32 size:4] autorelease];
}

@end
