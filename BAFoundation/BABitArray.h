//
//  BABitArray.h
//
//  Created by Brent Gulanowski on 09-09-27.
//  Copyright 2009 Bored Astronaut. All rights reserved.
//


#import "BASampleArray.h"


typedef void (^BABitArrayEnumerator) (NSUInteger bit);


@protocol BABitArray <NSObject>

@property (nonatomic, readonly) NSUInteger count;

- (BOOL)bit:(NSUInteger)index;

- (void)setBit:(NSUInteger)index;
- (void)setRange:(NSRange)bitRange;
- (void)setAll;

- (void)clearBit:(NSUInteger)index;
- (void)clearRange:(NSRange)bitRange;
- (void)clearAll;

- (NSUInteger)firstSetBit;
- (NSUInteger)lastSetBit;

@optional
// ranges for readBits:range: and writeBits:range are bit ranges
- (void)readBits:(BOOL *)bits range:(NSRange)bitRange;
- (void)writeBits:(BOOL * const)bits range:(NSRange)bitRange;

- (NSUInteger)firstClearBit;
- (NSUInteger)lastClearBit;

@end


@interface BABitArray : NSObject<NSCopying, NSCoding, BABitArray> {
    
    BASampleArray *size;
    
	unsigned char *buffer;
	NSUInteger bufferLength; // in bytes, rounded up
	NSUInteger length;       // in bits as initialized
	NSUInteger count;        // number of set bits
    
    BOOL enableArchiveCompression;
}

@property (nonatomic) BOOL enableArchiveCompression;

@property (readonly) BASampleArray *size;
@property (readonly) NSData *bufferData;
@property (readonly) NSUInteger length;

- (BOOL)isEqualToBitArray:(BABitArray *)other;

- (NSUInteger)nextAfter:(NSUInteger)prev;
- (void)enumerate:(BABitArrayEnumerator)block;

- (BOOL)checkCount;
- (void)refreshCount;

// range for readBytes:range: and writeBytes:range: is byte range (not bit range) 
- (void)readBytes:(unsigned char *)bytes range:(NSRange)byteRange;
- (void)writeBytes:(unsigned char *)bytes range:(NSRange)byteRange;

- (NSData *)dataForRange:(NSRange)bitRange;

- (id)initWithLength:(NSUInteger)bits size:(BASampleArray *)vector;
- (id)initWithLength:(NSUInteger)bits;
- (id)initWithData:(NSData *)data length:(NSUInteger)length;
// otherArray must be of equal or greater length; bitRange must fit within otherArray length
- (id)initWithBitArray:(BABitArray *)otherArray range:(NSRange)bitRange;

+ (BABitArray *)bitArrayWithLength:(NSUInteger)bits size:(BASampleArray *)vector;
+ (BABitArray *)bitArrayWithLength:(NSUInteger)bits;
+ (BABitArray *)bitArray8;
+ (BABitArray *)bitArray64;
+ (BABitArray *)bitArray512;
+ (BABitArray *)bitArray4096; // 16^3, our zone volume

@end


// Conveniences for bit arrays initialized with a 2-dimensional size use these to update sub-rectangles

@interface BABitArray (SpatialStorage)

- (void)setRect:(NSRect)rect;
- (void)clearRect:(NSRect)rect;

- (void)writeRect:(NSRect)rect fromArray:(BABitArray *)bitArray offset:(NSPoint)origin;
- (void)writeRect:(NSRect)rect fromArray:(BABitArray *)bitArray;

- (BABitArray *)subArrayWithRect:(NSRect)rect;

- (id)initWithBitArray:(BABitArray *)otherArray rect:(NSRect)rect;

@end


@interface BASampleArray (BABitArraySupport)
- (NSSize)size2d;
+ (BASampleArray *)sampleArrayForSize2d:(NSSize)size;
@end
