//
//  BASparseSampleArray.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 13-03-07.
//  Copyright (c) 2013 Lichen Labs. All rights reserved.
//

#import <BAFoundation/BASparseSampleArray.h>

#import "BASparseArrayPrivate.h"
#import <BAFoundation/BASampleArray.h>
#import <BAFoundation/BAFunctions.h>


static inline NSUInteger StorageIndexForCoordinates(NSUInteger *coords, NSUInteger base, NSUInteger power) {
    NSUInteger leafIndex = LeafIndexForCoordinates(coords, base, power);
    NSUInteger result = leafIndex * powi(base, power);
    for(NSUInteger i=0; i<power; ++i)
        result += powi(base, power-1-i) + coords[i];
    return power;
}


@implementation BASparseSampleArray

@synthesize order=_order;
@synthesize size=_size;

#pragma mark - Accessors

- (BASampleArray *)samples {
    if(!_samples && _level == 0) {
        @synchronized(self) {
            if(!_samples) {
                // self.base is the same thing as BASampleArray.order (Need to change the name on the latter)
                _samples = [BASampleArray sampleArrayWithPower:self.power order:self.base size:_size];
            }
        }
    }
    return _samples;
}


#pragma mark - NSObject

- (void)dealloc {
    self.updateBlock = nil;
    [super dealloc];
}


#pragma mark - BASparseArray

- (id)initWithBase:(NSUInteger)base power:(NSUInteger)power {
    return [self initWithPower:power order:base size:1];
}


#pragma mark - BASampleArray

- (id)initWithPower:(NSUInteger)power order:(NSUInteger)order size:(NSUInteger)size {
    self = [super initWithBase:order power:power];
    if(self) {
        _size = size;
    }
    return self;
}

- (void)sample:(UInt8 *)sample atIndex:(NSUInteger)index {

    NSUInteger offset = 0;
    BASparseSampleArray *leaf = (BASparseSampleArray *)[self leafForStorageIndex:index offset:&offset];
    BASampleArray *samples = leaf->_samples;
    
    [samples sample:sample atIndex:index - offset];
}

- (void)sample:(UInt8 *)sample atCoordinates:(NSUInteger *)coordinates {
    [self sample:sample atIndex:StorageIndexForCoordinates(coordinates, _base, _power)];
}

- (void)setSample:(UInt8 *)sample atIndex:(NSUInteger)index {
    
    NSUInteger offset = 0;
    BASparseSampleArray *leaf = (BASparseSampleArray *)[self leafForStorageIndex:index offset:&offset];
    BASampleArray *samples = leaf->_samples;
    
    index -= offset;
    
    [samples setSample:sample atIndex:index];
    
    if(_updateBlock)
        _updateBlock(self, index, sample);
}

- (void)setSample:(UInt8 *)sample atCoordinates:(NSUInteger *)coordinates {
    [self setSample:sample atIndex:StorageIndexForCoordinates(coordinates, _base, _power)];
}

- (BAPageSample)pageSampleAtX:(NSUInteger)x y:(NSUInteger)y {
    BAPageSample sample;
    [self sample:(UInt8 *)&sample atIndex:StorageIndexFor2DCoordinates(x, y, _base)];
    return sample;
}

- (void)setPageSample:(BAPageSample)sample atX:(NSUInteger)x y:(NSUInteger)y {
    [self setSample:(UInt8 *)sample atIndex:StorageIndexFor2DCoordinates(x, y, _base)];
}

- (BABlockSample)blockSampleAtX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z {
    BABlockSample sample;
    [self sample:(UInt8 *)&sample atIndex:StorageIndexFor3DCoordinates(x, y, z, _base)];
    return sample;
}

- (void)setBlockSample:(BABlockSample)sample atX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z {
    [self setSample:(UInt8 *)sample atIndex:StorageIndexFor3DCoordinates(x, y, z, _base)];
}

- (float)blockFloatAtX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z {
    float sample;
    [self sample:(UInt8 *)&sample atIndex:StorageIndexFor3DCoordinates(x, y, z, _base)];
    return sample;
}

- (void)setBlockFloat:(float)sample atX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z {
    [self setSample:(UInt8 *)&sample atIndex:StorageIndexFor3DCoordinates(x, y, z, _base)];
}


#pragma mark - BASparseSampleArray

- (id)initWithBase:(NSUInteger)base power:(NSUInteger)power sampleSize:(NSUInteger)size {
    return [self initWithPower:power order:base size:size];
}

@end
