//
//  BABitArray.h
//
//  Created by Brent Gulanowski on 09-09-27.
//  Copyright 2009 Bored Astronaut. All rights reserved.
//


typedef void (^BABitArrayEnumerator) (NSUInteger bit);


@protocol BABitArray <NSObject>

@property (nonatomic, readonly) NSUInteger count;

- (BOOL)bit:(NSUInteger)index;

- (void)setBit:(NSUInteger)index;
- (void)setRange:(NSRange)range;
- (void)setAll;

- (void)clearBit:(NSUInteger)index;
- (void)clearRange:(NSRange)range;
- (void)clearAll;

- (NSUInteger)firstSetBit;
- (NSUInteger)lastSetBit;

@optional
- (void)readBits:(BOOL *)bits range:(NSRange)range;
- (void)writeBits:(BOOL * const)bits range:(NSRange)range;

- (NSUInteger)firstClearBit;
- (NSUInteger)lastClearBit;

@end


@interface BABitArray : NSObject<NSCopying, NSCoding, BABitArray> {
	unsigned char *buffer;
	NSUInteger bufferLength; // in bytes, rounded up
	NSUInteger length;       // in bits as initialized
	NSUInteger count;        // number of set bits
    
    BOOL enableArchiveCompression;
}

@property (nonatomic) BOOL enableArchiveCompression;

@property (readonly) NSData *bufferData;
@property (readonly) NSUInteger length;

- (NSUInteger)nextAfter:(NSUInteger)prev;
- (void)enumerate:(BABitArrayEnumerator)block;

- (BOOL)checkCount;
- (void)refreshCount;

- (id)initWithLength:(NSUInteger)bits;
- (id)initWithData:(NSData *)data length:(NSUInteger)length;

+ (BABitArray *)bitArrayWithLength:(NSUInteger)bits;
+ (BABitArray *)bitArray8;
+ (BABitArray *)bitArray64;
+ (BABitArray *)bitArray512;
+ (BABitArray *)bitArray4096; // 16^3, our zone volume

@end
