//
//  BASampleArray.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 12-04-22.
//  Copyright (c) 2012 Lichen Labs. All rights reserved.
//

#import <BAFoundation/BASampleArray.h>

#import <BAFoundation/BAFunctions.h>
#import "BANumber.h"


#pragma mark -
@implementation BASampleArray

#pragma mark - Properties
@dynamic samples;
@synthesize power=_power, order=_order, size=_size, count=_count;


#pragma mark - Accessors

- (UInt8 *)samples {
    return _samples;
}

- (NSData *)data {
    return [NSData dataWithBytesNoCopy:_samples length:_size * _count freeWhenDone:NO];
}

- (NSUInteger)length {
    return _size * _count;
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
    self = [self initWithPower:[aDecoder decodeIntegerForKey:@"power"] order:[aDecoder decodeIntegerForKey:@"order"] size:[aDecoder decodeIntegerForKey: @"size"]];
    if(self) {
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
    
    const NSUInteger maxOrder = [[self class] maxOrderForPower:power size:size];
    if (order > maxOrder) {
        NSString *reason = [NSString stringWithFormat:@"Could not meet storage requirements for requested sample array parameters. Choose order <= %td.", maxOrder];
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
    }
    
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

- (instancetype)init {
    return [self initWithPower:3 order:32 size:1];
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
    NSAssert(index <= _count, @"index %td beyond bounds %td", index, _count);
    memcpy(sample, _samples + index * _size, _size);
}

- (void)setSample:(UInt8 *)sample atIndex:(NSUInteger)index {
    NSAssert(index <= _count, @"index %td beyond bounds %td", index, _count);
    memcpy(_samples + index * _size, sample, _size);
}

- (void)readSamples:(UInt8 *)samples range:(NSRange)range {
    NSAssert(NSMaxRange(range) <= _count, @"range %@ beyond bounds %td", NSStringFromRange(range), _count);
    memcpy(samples, _samples+range.location * _size, range.length * _size);
}

- (void)writeSamples:(UInt8 *)samples range:(NSRange)range {
    NSAssert(NSMaxRange(range) <= _count, @"range %@ beyond bounds %td", NSStringFromRange(range), _count);
    memcpy(_samples+range.location*_size, samples, _size*range.length);
}

- (void)iterate:(void (^)(BANumber *, NSUInteger, UInt8 *))block {
    
    BANumber *indices = [[BANumber alloc] initWithBase:_order size:_power initialValue:0];
    const NSUInteger length = _size * _count;
    
    for (NSUInteger i = 0; i < length; i+=_size) {
        block(indices, i, &_samples[i]);
        [indices increment];
    }
}

static inline NSUInteger indexForCoordinates(NSUInteger *coordinates, NSUInteger power, NSUInteger order) {
    
    NSUInteger sampleIndex = coordinates[0];
    NSUInteger factor = order;
    
    for(NSUInteger i = 1; i < power; ++i) {
        sampleIndex += coordinates[i] * factor;
        factor *= order;
    }
    
    return sampleIndex;
}

// private, exposed to tests only
- (NSUInteger)indexForCoordinates:(NSUInteger *)coordinates {
    return indexForCoordinates(coordinates, _power, _order);
}

- (void)sample:(UInt8 *)sample atCoordinates:(NSUInteger *)coordinates {
     [self sample:sample atIndex:indexForCoordinates(coordinates, _power, _order)];
}

- (void)setSample:(UInt8 *)sample atCoordinates:(NSUInteger *)coordinates {
    [self setSample:sample atIndex:indexForCoordinates(coordinates, _power, _order)];
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

+ (instancetype)vectorWithOrder:(NSUInteger)order size:(NSUInteger)size {
    return (BASampleArray *)[[[self alloc] initWithPower:1 order:order size:size] autorelease];
}

+ (BASampleArray *)page {
    return (BASampleArray *)[[[self alloc] initWithPower:2 order:32 size:4] autorelease];
}

+(BASampleArray *)block {
    return (BASampleArray *)[[[self alloc] initWithPower:3 order:32 size:4] autorelease];
}

#pragma mark - Convenience
+ (NSUInteger)maxOrderForPower:(NSUInteger)power size:(NSUInteger)size {
    /*
     mem_size = size * order^power
     mem_size/size = order^power
     order = log<power>(memory_size/size>
     
     max_mem = NSUIntegerMax = 2^N - 1
     max_mem_plus_1 = 2^N; N = log2(NSUIntegerMax+1) = sizeof(NSUIntegerMax) * 8 = (32|64)
     
     mem_size <= max_mem
     mem_size < max_mem_plus_1
     
     let max_mem = size * max_order^power
     solve for max_order
     
     size * max_order^power = max_mem - 1
     size * max_order^power = 2^N - 1
     
     
     ASIDE:
     (2^3)^3 = (2*2*2)*(2*2*2)*(2*2*2) = 2^9 = 2^(3*3)
     a^4^2 = (a*a*a*a)*(a*a*a*a) = a^8 = a^(4*2)
     (a^b)^c = a^(b*c)
     
     
     let max_order = 2^M:
     size * 2^M^power = 2^N - 1
     size * 2^(M*power) = 2^N - 1
     
     let P = M * power:
     size * 2^P = 2^N - 1
     
     
     ASIDE:
     2^3 = 8
     log2(8) = 3
     2^1 = 2
     log2(2) = 1
     2^0 = 1
     log2(1) = 0
     
     
     let size = 2^Q, (so Q = log2(size)):
     2^Q * 2^P = 2^N - 1
     2^(Q+P) = 2^N - 1
     
     Q + P < N
     P < N - Q
     
     M*power < N - Q
     M < (N - Q)/power
     M < (N - Q)/power
     
     max_order < 2^((N - Q)/power)
     max_order < 2^((N - log2(size))/power)
     max_order < 2^((N - log2(size))/power)
     max_order >= 2^((N - log2(size))/power) - 1
     */
    
    if (size <= 1 && power <= 1) {
        return NSUIntegerMax;
    }
    
    static const NSUInteger N = sizeof(NSUInteger) * 8;
    const NSUInteger Q = (NSUInteger)ceil(log2f((float)size));
    const NSUInteger M = (N - Q) / power;
    
    return (1 << M) - 1;
}

@end
