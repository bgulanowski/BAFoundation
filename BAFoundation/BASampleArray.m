//
//  BASampleArray.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 12-04-22.
//  Copyright (c) 2012 Lichen Labs. All rights reserved.
//

#import "BASampleArray.h"

#import "BAFunctions.h"


#pragma mark -
@implementation BASampleArray

#pragma mark - Properties
@dynamic samples;
@synthesize power=_power, order=_order, size=_size, count=_count;


#pragma mark - Accessors

- (UInt8 *)samples {
    return _samples;
}


#pragma mark - NSObject
- (void)dealloc {
    if(_samples) free(_samples);
    [super dealloc];
}


#pragma mark - NSCoding
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:_power forKey:@"power"];
    [aCoder encodeInteger:_order forKey:@"order"];
    [aCoder encodeInteger:_size  forKey: @"size"];
    [aCoder encodeObject:[NSData dataWithBytesNoCopy:_samples length:_size*_count freeWhenDone:NO] forKey:@"sampleData"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if(self) {
        _power = [aDecoder decodeIntegerForKey:@"power"];
        _order = [aDecoder decodeIntegerForKey:@"order"];
        _size  = [aDecoder decodeIntegerForKey: @"size"];
        _count = powi(_order, _power);
        _samples = malloc(_size*_count);

        NSAssert(_samples, @"Failed to allocate memory for BASampleArray");

        NSData *sampleData = [aDecoder decodeObjectForKey:@"sampleData"];
        
        [sampleData getBytes:_samples length:_size*_count];
    }
    return self;
}


#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {

    BASampleArray *copy = [[BASampleArray alloc] initWithPower:_power order:_order size:_size];
    
    memcpy(copy->_samples, _samples, _size*_count);
    
    return copy;
}


#pragma mark - BASampleArray
- (id)initWithPower:(NSUInteger)power order:(NSUInteger)order size:(NSUInteger)size {
    self = [super init];
    if(self) {

        _power = power;
        _order = order;
        _size  =  size;
        _count = powi(_order, _power);
        _samples = malloc(_size*_count);

        NSAssert(_samples, @"Failed to allocate memory for BASampleArray");
    }
    return self;
}

- (BOOL)isEqualToSampleArray:(BASampleArray *)other {
    
    if(other == self)
        return YES;
    
    if(!other)
        return NO;
    
    if(_power != other->_power ||
       _order != other->_order ||
       _size  != other->_size)
        return NO;
    
    return 0 == memcmp(_samples, other->_samples, _size*_count);
}

- (void)sample:(UInt8 *)sample atIndex:(NSUInteger)index {
    memcpy(sample, _samples+index*_size, _size);
}

- (void)setSample:(UInt8 *)sample atIndex:(NSUInteger)index {
    memcpy(_samples+index*_size, sample, _size);
}

- (void)readSamples:(UInt8 *)samples range:(NSRange)range {
    memcpy(samples, _samples+range.location*_size, _size*range.length);
}

- (void)writeSamples:(UInt8 *)samples range:(NSRange)range {
    memcpy(_samples+range.location*_size, samples, _size*range.length);
}

static inline NSUInteger indexForCoordinates(uint32_t *coordinates, NSUInteger power) {
    
    NSUInteger sampleIndex = 0;
    NSUInteger factor = 1;
    
    for(NSUInteger i=0; i<power; ++i) {
        sampleIndex += coordinates[i] * factor++;
    }
    
    return sampleIndex;
}

- (void)sample:(UInt8 *)sample atCoordinates:(uint32_t *)coordinates {
     [self sample:sample atIndex:indexForCoordinates(coordinates, _power)];
}

- (void)setSample:(UInt8 *)sample atCoordinates:(uint32_t *)coordinates {
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
