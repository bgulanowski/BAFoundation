//
//  BABitArray.h
//
//  Created by Brent Gulanowski on 09-09-27.
//  Copyright 2009 Bored Astronaut. All rights reserved.
//


#import "BASampleArray.h"


typedef void (^BABitArrayEnumerator) (NSUInteger bit);


@protocol BABitArray <NSObject>

@property (readonly) NSUInteger length;
@property (readonly) NSUInteger count;

- (BOOL)bit:(NSUInteger)index;

- (void)setBit:(NSUInteger)index;
- (void)setRange:(NSRange)bitRange;
- (void)setAll;

- (void)clearBit:(NSUInteger)index;
- (void)clearRange:(NSRange)bitRange;
- (void)clearAll;

- (NSUInteger)firstSetBit;
- (NSUInteger)lastSetBit;

// ranges for readBits:range: and writeBits:range are bit ranges
- (NSUInteger)readBits:(BOOL *)bits range:(NSRange)bitRange;
- (NSUInteger)writeBits:(BOOL * const)bits range:(NSRange)bitRange;

- (NSUInteger)firstClearBit;
- (NSUInteger)lastClearBit;

- (NSString *)stringForRange:(NSRange)range;

@end


// Conveniences for bit arrays initialized with a 2-dimensional size use these to update sub-rectangles

@protocol BABitArray2D <BABitArray>

- (id)initWithBitArray:(id<BABitArray>)otherArray rect:(CGRect)rect;

- (BASampleArray *)size;

// power 2 conveniences
- (BOOL)bitAtX:(NSUInteger)x y:(NSUInteger)y;
- (void)setBitAtX:(NSUInteger)x y:(NSUInteger)y;
- (void)clearBitAtX:(NSUInteger)x y:(NSUInteger)y;

// power 3 conveniences
- (BOOL)bitAtX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z;
- (void)setBitAtX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z;
- (void)clearBitAtX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z;

- (void)setRect:(CGRect)rect;
- (void)clearRect:(CGRect)rect;

- (void)writeRect:(CGRect)rect fromArray:(id<BABitArray2D>)bitArray offset:(CGPoint)origin;

- (id<BABitArray2D>)subArrayWithRect:(CGRect)rect;

@optional
- (NSArray *)rowStringsForRect:(CGRect)rect;
- (NSString *)stringForRect:(CGRect)rect;
- (NSString *)stringForRect;

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

- (BOOL)isEqualToBitArray:(BABitArray *)other;

- (NSUInteger)nextAfter:(NSUInteger)prev;
- (void)enumerate:(BABitArrayEnumerator)block;

- (BOOL)checkCount;
- (void)refreshCount;

// These are inefficient and not tested
- (NSUInteger)indexOfNthSetBit:(NSUInteger)n;
- (NSUInteger)indexOfNthClearBit:(NSUInteger)n;

// range for readBytes:range: and writeBytes:range: is byte range (not bit range) 
- (void)readBytes:(unsigned char *)bytes range:(NSRange)byteRange;
- (void)writeBytes:(unsigned char *)bytes range:(NSRange)byteRange;

- (NSData *)dataForRange:(NSRange)bitRange;

- (id)initWithLength:(NSUInteger)bits size:(BASampleArray *)vector;
- (id)initWithLength:(NSUInteger)bits;
- (id)initWithData:(NSData *)data length:(NSUInteger)length;
// otherArray must be of equal or greater length; bitRange must fit within otherArray length
- (id)initWithBitArray:(BABitArray *)otherArray range:(NSRange)bitRange;

- (BABitArray *)reverseBitArray;

+ (BABitArray *)bitArrayWithLength:(NSUInteger)bits size:(BASampleArray *)vector;
+ (BABitArray *)bitArrayWithLength:(NSUInteger)bits;
+ (BABitArray *)bitArray8;
+ (BABitArray *)bitArray64;
+ (BABitArray *)bitArray512;
+ (BABitArray *)bitArray4096; // 16^3, our zone volume

@end


@interface BABitArray (SpatialStorage) <BABitArray2D>
- (id)initWithSize:(CGSize)initSize;
- (BABitArray *)bitArrayByFlippingColumns;
- (BABitArray *)bitArrayByFlippingRows;
- (BABitArray *)bitArrayByRotating:(NSInteger)quarters; // "quarters" are increments are 90 degrees
- (void)writeRect:(CGRect)rect fromArray:(id<BABitArray2D>)bitArray;
+ (BABitArray *)bitArrayWithSize:(CGSize)initSize;
@end


@interface BASampleArray (BABitArraySupport)
- (CGSize)size2d;
- (void)size3d:(NSUInteger*)size;
+ (BASampleArray *)sampleArrayForSize2d:(CGSize)size;
+ (BASampleArray *)sampleArrayForSize3d:(NSUInteger *)size;
@end
