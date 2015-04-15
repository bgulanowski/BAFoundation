//
//  BABitArrayTester.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 11-03-22.
//  Copyright 2011 Bored Astronaut. All rights reserved.
//

#import "BABitArrayTester.h"

#import <BAFoundation/BABitArray.h>
#import <BAFoundation/BAFunctions.h>

@interface BABitArray (Testing)
+ (instancetype)testBitArray8by8;
+ (instancetype)testBitArray128by128;
+ (instancetype)testBitArray256by256;
@end

@implementation BABitArrayTester

- (void)test01SimpleSet {
	
	BABitArray *ba = [BABitArray bitArray8];
	
	STAssertNotNil(ba, @"Failed to allocate bit array 8");
    
    for(NSUInteger i=0; i<8; ++i)
        STAssertFalse([ba bit:i], @"bit %lu should not be set", i);
    STAssertEquals([ba firstSetBit], NSNotFound, @"first set bit should be Not Found");
    STAssertEquals([ba lastSetBit], NSNotFound, @"last set bit should be Not Found");
    STAssertEquals([ba firstClearBit], 0ul, @"first clear bit did not match");
    STAssertEquals([ba lastClearBit], 7ul, @"last clear bit did not match");
	
    [ba setBit:0];
    STAssertEquals([ba firstSetBit], 0ul, @"first set bit did not match");
    STAssertEquals([ba lastSetBit], 0ul, @"last set bit did not match");
    STAssertEquals([ba firstClearBit], 1ul, @"first clear bit did not match");
    STAssertEquals([ba lastClearBit], 7ul, @"last clear bit did not match");
    
    [ba setBit:7];
    STAssertEquals([ba firstSetBit], 0ul, @"first set bit did not match");
    STAssertEquals([ba lastSetBit], 7ul, @"last set bit did not match");
    STAssertEquals([ba firstClearBit], 1ul, @"first clear bit did not match");
    STAssertEquals([ba lastClearBit], 6ul, @"last clear bit did not match");

	[ba setAll];
	STAssertTrue([ba bit:0], @"Failed to set bit 0");
	STAssertTrue([ba bit:7], @"Failed to set bit 7");
    STAssertEquals([ba firstSetBit], 0ul, @"first set bit did not match");
    STAssertEquals([ba lastSetBit], 7ul, @"last set bit did not match");
    STAssertEquals([ba firstClearBit], NSNotFound, @"first clear bit did not match");
    STAssertEquals([ba lastClearBit], NSNotFound, @"last clear bit did not match");

    [ba clearBit:1];
    [ba clearBit:6];
	
    STAssertEquals([ba firstClearBit], 1ul, @"first clear bit did not match");
    STAssertEquals([ba lastClearBit], 6ul, @"last clear bit did not match");
}

- (void)test02Count {
	
	BABitArray *ba = [BABitArray bitArray64];
	NSUInteger count = 0;
	
	STAssertNotNil(ba, @"Failed to allocate bit array 64");
	STAssertTrue([ba checkCount], @"Failed count check (%u)", ba.count);
	
	[ba setAll];
	STAssertTrue([ba bit:0], @"Failed to set bit 0");
	STAssertTrue([ba bit:63], @"Failed to set bit 63");
	STAssertTrue([ba checkCount], @"Failed count check (%u)", ba.count);
	
	[ba clearAll];
	STAssertFalse([ba bit:0], @"Failed to clear bit 0");
	STAssertFalse([ba bit:63], @"Failed to clear bit 63");
	STAssertTrue([ba checkCount], @"Failed count check (%u)", ba.count);
	
	[ba setBit:33];
	++count;
	STAssertTrue([ba bit:33], @"Failed to set bit 33");
	STAssertEquals(ba.count, count, @"Wrong count (%u; expected %u)", ba.count, count);
	STAssertTrue([ba checkCount], @"Failed count check (%u)", ba.count);
	
	NSRange range = NSMakeRange(40, 15);
	[ba setRange:range];
	count+=15;
	
	STAssertTrue([ba bit:40], @"Failed to set bit 40 when setting range %@", NSStringFromRange(range));
	STAssertEquals(ba.count, count, @"Wrong count (%u; expected %u)", ba.count, count);
	STAssertTrue([ba checkCount], @"Failed count check (%u)", ba.count);
	
	range = NSMakeRange(7, 10);
	[ba setRange:range];
	count+=10;
	STAssertTrue([ba bit:7], @"Failed to set bit 7 when setting range %@", NSStringFromRange(range));
	STAssertTrue([ba bit:12], @"Failed to set bit 12 when setting range %@", NSStringFromRange(range));
	STAssertTrue([ba bit:16], @"Failed to set bit 16 when setting range %@", NSStringFromRange(range));
	STAssertEquals(ba.count, count, @"Wrong count (%u; expected %u)", ba.count, count);
	STAssertTrue([ba checkCount], @"Failed count check (expected: %u)", ba.count);
	
	[ba setRange:NSMakeRange(20, 17)];
	count+=(17-1); // 33 is already set
	STAssertEquals(ba.count, count, @"Wrong count (%u; expected %u)", ba.count, count);
	STAssertTrue([ba checkCount], @"Failed count check (%u)", ba.count);
	
	[ba clearRange:NSMakeRange(28, 4)];
	count-=4;
	STAssertTrue([ba bit:20], @"Failed to set bit 20");
	STAssertFalse([ba bit:30], @"Failed to clear bit 30");
	STAssertTrue([ba bit:35], @"Failed to set bit 35");
	STAssertEquals(ba.count, count, @"Wrong count (%u; expected %u)", ba.count, count);
	STAssertTrue([ba checkCount], @"Failed count check (%u)", ba.count);
    
    ba = [BABitArray bitArrayWithLength:8*8 size:[BASampleArray sampleArrayForSize2:BASize2Make(8, 8)]];
    
    [ba setDiagonalReverse:NO min:0 max:8];
    STAssertEquals([ba count], (NSUInteger)8, @"Failed count after set diagonal");
    
    [ba setRow:6 min:0 max:8];
    STAssertEquals([ba count], (NSUInteger)15, @"Failed count after set row");
    
    [ba setColumn:4 min:0 max:8];
    STAssertEquals([ba count], (NSUInteger)21, @"Failed count after set column");
}

- (void)test03FirstLast {
	
	BABitArray *ba = [BABitArray bitArray64];
	
	[ba setBit:12];
	[ba setBit:31];
	
	NSUInteger fs = [ba firstSetBit];
	NSUInteger ls = [ba lastSetBit];
	NSUInteger fc = [ba firstClearBit];
	NSUInteger lc = [ba lastClearBit];
	
	STAssertTrue(12==fs, @"First set failed. Expected %qu; actual: %qu", 12, fs);
	STAssertTrue(0==fc, @"First clear failed. Expected %qu; actual: %qu", 0, fc);
	STAssertTrue(31==ls, @"Last set failed. Expected %qu; actual: %qu", 31, ls);
	STAssertTrue(63==lc, @"Last clear failed. Expected %qu; actual: %qu", 63, lc);
}

- (void)test04EqualitySimplePositive {
	
	BABitArray *ba1 = [BABitArray bitArray8];
	BABitArray *ba2 = [BABitArray bitArray8];
	
	STAssertTrue([ba1 isEqualToBitArray:ba2], @"Expected: %@; Actual: %@", ba1, ba2);
}

- (void)test05EqualitySimpleNegative {
	
	BABitArray *ba1 = [BABitArray bitArray8];
	BABitArray *ba2 = [BABitArray bitArray8];
    
    [ba1 setBit:7];
	
	STAssertFalse([ba1 isEqualToBitArray:ba2], @"Expected: %@; Actual: %@", ba1, ba2);
}

- (void)test10Copy {
	
    BABitArray *ba1 = [BABitArray bitArray64];
    BABitArray *ba2 = [[ba1 copy] autorelease];
    
    STAssertTrue([ba1 isEqualToBitArray:ba2], @"BABitArray copy equality test failed");
    
    [ba2 setBit:63];
    
    STAssertFalse([ba1 isEqualToBitArray:ba2], @"BABitArray copy modify inequality test failed");
}

- (void)test11EncodeDecode {
    
    BABitArray *ba1 = [BABitArray bitArray64];

    [ba1 setBit:11];
    [ba1 setBit:25];
    [ba1 setRange:NSMakeRange(33, 12)];
    [ba1 setBit:63];
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:ba1];
    BABitArray *ba2 = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    STAssertTrue([ba1 isEqualToBitArray:ba2], @"BABitArray encode-decode equality test failed");
}

- (void)test20Enumeration {
    
    BABitArray *ba1 = [BABitArray bitArray64];
    __block NSUInteger checkCount = 0;
    
    [ba1 setBit:11];
    [ba1 setBit:25];
    [ba1 setRange:NSMakeRange(33, 12)];
    [ba1 setBit:63];
    
    BABitArray *ba2 = [ba1 copy];

    [ba1 enumerate:^(NSUInteger bit) {
        [ba2 clearBit:bit];
        ++checkCount;
    }];
    
    STAssertTrue(0 == [ba2 count], @"enumeration test failed");
    STAssertEquals(checkCount, [ba1 count], @"enumeration test failed");
}

- (void)test30WriteRange {
    
    BABitArray *ba1 = [BABitArray bitArray64];
    BOOL bits[16];
    BOOL check[16];
    
    bits[0] = YES;
    
    [ba1 writeBits:bits range:NSMakeRange(30, 1)];
    
    STAssertEquals([ba1 count], (NSUInteger)1, @"Write bits failed; array count incorrect. Expected: 1. Actual: %d", [ba1 count]);
    
    [ba1 readBits:check range:NSMakeRange(30, 1)];
    
    STAssertEquals(check[0], bits[0], @"Read bits failed.");
    
    bits[1] = bits[5] = bits[6] = bits[11] = bits[15] = YES;
    
    [ba1 writeBits:bits range:NSMakeRange(0, 16)];
    
    STAssertEquals([ba1 count], (NSUInteger)7, @"Write bits failed; array count incorrect. Expected: 7. Actual: %d", [ba1 count]);
    
    [ba1 readBits:check range:NSMakeRange(0, 16)];
    
    for(NSUInteger i=0; i<16; ++i) {
        STAssertEquals(check[i], bits[i], @"Read bits failed at bit %d", (int)i);
        if(check[i] != bits[i])
            break;
    }
}

- (void)test31DataForRange {
		
    BABitArray *ba = [BABitArray bitArray64];
	
	// 00001000 01100000
    [ba setBit:4];
    [ba setBit:10];
    [ba setBit:11];
	
#if SEQUENTIAL_BIT_ORDER
    unsigned char c[2] = { 0b00001000, 0b00110000 };
	STAssertEquals(c[0], (unsigned char)0x08, @"Bit order mismatch");
	STAssertEquals(c[1], (unsigned char)0x30, @"Bit order mismatch");
#else
    unsigned char c[2] = { 0b00010000, 0b00001100 };
#endif

	NSData *e = [NSData dataWithBytes:c length:2];
    NSData *a = [ba dataForRange:NSMakeRange(0, 16)];
	
	STAssertEqualObjects(a, e, @"-dataForRange: failed.");

#if SEQUENTIAL_BIT_ORDER
    c[0] = 0b10000011;
    c[1] = 0b00000000;
	STAssertEquals(c[0], (unsigned char)0x83, @"Bit order mismatch");
	STAssertEquals(c[1], (unsigned char)0x0, @"Bit order mismatch");
#else
    c[0] = 0b11000001;
    c[1] = 0b00000000;
#endif

	e = [NSData dataWithBytes:c length:1];
	// ----1000 0110----
	// aka 10000110
	a = [ba dataForRange:NSMakeRange(4, 8)];
    
    BABitArray *t1 = [[[BABitArray alloc] initWithData:a length:8] autorelease];
    BABitArray *t2 = [[[BABitArray alloc] initWithBitArray:ba range:NSMakeRange(4, 8)] autorelease];
    
    STAssertEqualObjects(a, e, @"-dataForRange: failed.");
	STAssertEqualObjects(t1, t2, @"-initWithData:length: failed.");
	
	// 00010000 01100000 00010101 10000000
    [ba setBit:20];
    [ba setBit:22];
    [ba setBit:24];
    [ba setBit:25];

#if SEQUENTIAL_BIT_ORDER
    c[0] = 0b11000000;
    c[1] = 0b00101010;
	STAssertEquals(c[0], (unsigned char)0xC0, @"Bit order mismatch");
	STAssertEquals(c[1], (unsigned char)0x2A, @"Bit order mismatch");
#else
    c[0] = 0b00000011;
    c[1] = 0b01010100;
	STAssertEquals(c[0], (unsigned char)0x03, @"Bit order mismatch");
	STAssertEquals(c[1], (unsigned char)0x54, @"Bit order mismatch");
#endif
    
    e = [NSData dataWithBytes:c length:2];
	// -------- -1100000 00010101 -0000000
	// aka      11000000 00101010
    a = [ba dataForRange:NSMakeRange(10, 15)];

    t1 = [[[BABitArray alloc] initWithData:a length:15] autorelease];
    t2 = [[[BABitArray alloc] initWithBitArray:ba range:NSMakeRange(10, 15)] autorelease];

    STAssertEqualObjects(a, e, @"-dataForRange: failed.");
	STAssertEqualObjects(t1, t2, @"-initWithData:length: failed.");
}

- (void)test32SubArray {
    
    BABitArray *ba1 = [BABitArray testBitArray256by256];
    BARegion2 region = BARegion2Make( 64, 64, 128, 128);

    [ba1 setRegion2:region];
    
    NSUInteger e = (NSUInteger)128*128;
    NSUInteger a = [ba1 count];
    
    STAssertEquals(a, e, @"setRect: failed; count is wrong. Expected: %u. Actual: %u", (unsigned)e, (unsigned)a);
    
    BABitArray *ba = (BABitArray *)[ba1 subArrayWithRegion:region];
    BABitArray *be = [BABitArray testBitArray128by128];
    
    [be setAll];
    
    STAssertTrue([ba isEqualToBitArray:be], @"subArrayWithRect: failed; Expected: %@. Actual: %@", be, ba);
}

- (void)test40RowFlip {
    
    BABitArray *ba1 = [BABitArray testBitArray8by8];
    [ba1 setDiagonalReverse:NO min:0 max:8];
    [ba1 setRow:6 min:0 max:8];
    
    BABitArray *e = [BABitArray testBitArray8by8];
    [e setDiagonalReverse:YES min:0 max:8];
    [e setRow:1 min:0 max:8];
    
    BABitArray *a = [ba1 bitArrayByFlippingRows];
    
    STAssertTrue([a isEqualToBitArray:e], @"flipping rows failed");
}

- (void)test41ColumnFlip {
    
    BABitArray *ba1 = [BABitArray testBitArray8by8];
    [ba1 setDiagonalReverse:NO min:0 max:8];
    [ba1 setColumn:6 min:0 max:8];
    
    BABitArray *e = [BABitArray testBitArray8by8];
    [e setDiagonalReverse:YES min:0 max:8];
    [e setColumn:1 min:0 max:8];

    BABitArray *a = [ba1 bitArrayByFlippingColumns];
    
    STAssertTrue([a isEqualToBitArray:e], @"flipping columns failed");
}

- (void)test42Rotation90 {
    
    BABitArray *ba1 = [BABitArray testBitArray8by8];
    [ba1 setDiagonalReverse:NO min:0 max:8];
    [ba1 setColumn:5 min:0 max:8];
    
    BABitArray *e = [BABitArray testBitArray8by8];
    [e setDiagonalReverse:YES min:0 max:8];
    [e setRow:5 min:0 max:8];
    
    BABitArray *a = [ba1 bitArrayByRotating:1];
    
    STAssertTrue([a isEqualToBitArray:e], @"rotation by 90 degrees failed");
}

- (void)test43Rotation180 {
    
    BABitArray *ba1 = [BABitArray testBitArray8by8];
    
    [ba1 setDiagonalReverse:NO min:0 max:8];
    [ba1 setColumn:2 min:0 max:8];
    [ba1 setRow:4 min:0 max:8];
    
    BABitArray *e = [BABitArray testBitArray8by8];
    [e setDiagonalReverse:NO min:0 max:8];
    [e setColumn:5 min:0 max:8];
    [e setRow:3 min:0 max:8];

    BABitArray *a = [ba1 bitArrayByRotating:2];
    
    STAssertTrue([a isEqualToBitArray:e], @"rotation by 180 degrees failed");
}

- (void)test44Rotation270 {
    
    BABitArray *ba1 = [BABitArray testBitArray8by8];
    
    [ba1 setDiagonalReverse:NO min:0 max:8];
    [ba1 setColumn:2 min:0 max:8];
    
    BABitArray *e = [BABitArray testBitArray8by8];
    [e setDiagonalReverse:YES min:0 max:8];
    [e setRow:5 min:0 max:8];
    
    BABitArray *a = [ba1 bitArrayByRotating:3];
    
    STAssertTrue([a isEqualToBitArray:e], @"rotation by 90 degrees failed");
}

@end


@implementation BABitArray (TestingAdditions)

- (void)setDiagonalReverse:(BOOL)reverse min:(NSUInteger)min max:(NSUInteger)max {
    if(reverse) {
        for (NSUInteger i=min; i<max; ++i)
            [self setBitAtX:max-1-i y:i];
    }
    else {
        for (NSUInteger i=min; i<max; ++i)
            [self setBitAtX:i y:i];
    }
}

- (void)setRow:(NSUInteger)row min:(NSUInteger)min max:(NSUInteger)max {
    for (NSUInteger i=min; i<max; ++i)
        [self setBitAtX:i y:row];
}

- (void)setColumn:(NSUInteger)column min:(NSUInteger)min max:(NSUInteger)max {
    for (NSUInteger i=min; i<max; ++i)
        [self setBitAtX:column y:i];
}

@end

@implementation BABitArray (Testing)

+ (instancetype)testBitArrayWithSize2:(BASize2)size2 {
    BASampleArray *sa = [BASampleArray sampleArrayForSize2:size2];
    return [BABitArray bitArrayWithLength:size2.width * size2.height size:sa];

}

+ (instancetype)testBitArray128by128 {
    return [self testBitArrayWithSize2:BASize2Make(128, 128)];
}

+ (instancetype)testBitArray256by256 {
    return [self testBitArrayWithSize2:BASize2Make(256, 256)];
}

+ (instancetype)testBitArray8by8 {
    return [self testBitArrayWithSize2:BASize2Make(8, 8)];
}

@end
