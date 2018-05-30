//
//  BASampleArray.h
//  BAFoundation
//
//  Created by Brent Gulanowski on 12-04-22.
//  Copyright (c) 2012 Lichen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * A Sample Array encapsulates an indexed block of memory. The length of the array and the size (in bytes) of
 * array elements are set at creation. The Sample Array interface takes care of calculating offsets. Values
 * are written to or read from the array by reference.
 *
 * A sample array can be multi-dimensional, and defined by its power. For a one-dimensional array, the order
 * is its length. For a multi-dimensional array, the length is the order raised to the power.
 *
 * The BASampleArray protocol defines the minimal interface for a sample array.
 */

@protocol BASampleArray <NSObject>

- (id)initWithPower:(NSUInteger)power order:(NSUInteger)order size:(NSUInteger)size;

- (void)sample:(UInt8 *)sample atIndex:(NSUInteger)index;
- (void)setSample:(UInt8 *)sample atIndex:(NSUInteger)index;
- (void)sample:(UInt8 *)sample atCoordinates:(NSUInteger *)coordinates;
- (void)setSample:(UInt8 *)sample atCoordinates:(NSUInteger *)coordinates;

@optional
- (void)readSamples:(UInt8 *)samples range:(NSRange)range;
- (void)writeSamples:(UInt8 *)samples range:(NSRange)range;

@end

/**
 * The BASampleArray class realizes the BASampleArray protocol. It extend the protocol with read-only
 * accessors to the fundamental properties of the array, as well as a derived count of elements.
 *
 * In addition, BASampleArray (class) defines convenience methods for a specialized 2- and 3-dimensional
 * versions called "page" and "block". A page is a 32x32 array of 4-byte samples. A block is 32x32x32.
 */

@interface BASampleArray : NSObject<NSCoding, NSCopying, BASampleArray> {
    
    UInt8 *_samples;
    
    NSUInteger _power; // the number of dimensions
    NSUInteger _order; // samples per dimension - the same in all dimensions
    NSUInteger _size;  // bytes per sample, starting at 1
    NSUInteger _count;
}

// These are immutable
@property (nonatomic, readonly) UInt8 *samples;

@property (nonatomic, readonly) NSUInteger power;
@property (nonatomic, readonly) NSUInteger order;
@property (nonatomic, readonly) NSUInteger size;
@property (nonatomic, readonly) NSUInteger count;

@property (nonatomic, readonly) NSData *data;

- (id)initWithPower:(NSUInteger)power order:(NSUInteger)order size:(NSUInteger)size NS_DESIGNATED_INITIALIZER;

- (BOOL)isEqualToSampleArray:(BASampleArray *)other;

- (UInt32)pageSampleAtX:(NSUInteger)x y:(NSUInteger)y;
- (void)setPageSample:(UInt32)sample atX:(NSUInteger)x y:(NSUInteger)y;
- (UInt32)blockSampleAtX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z;
- (void)setBlockSample:(UInt32)sample atX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z;

- (float)blockFloatAtX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z;
- (void)setBlockFloat:(float)sample  atX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z;

+ (BASampleArray *)sampleArrayWithPower:(NSUInteger)power order:(NSUInteger)order size:(NSUInteger)size;
+ (BASampleArray *)page;  // power=2, order=32, size=4 =>   4kB
+ (BASampleArray *)block; // power=3, order=32, size=4 => 128kB

@end
