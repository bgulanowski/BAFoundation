//
//  BABitArrayTester.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 11-03-22.
//  Copyright 2011 Bored Astronaut. All rights reserved.
//

#import "BABitArrayTester.h"

#import <BAFoundation/BABitArray.h>


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

- (void)testEqualitySimplePositive {
	
	BABitArray *ba1 = [BABitArray bitArray8];
	BABitArray *ba2 = [BABitArray bitArray8];
	
	STAssertTrue([ba1 isEqual:ba2], @"Expected: %@; Actual: %@", ba1, ba2);
}

- (void)testEqualitySimpleNegative {
	
	BABitArray *ba1 = [BABitArray bitArray8];
	BABitArray *ba2 = [BABitArray bitArray8];
    
    [ba1 setBit:7];
	
	STAssertFalse([ba1 isEqual:ba2], @"Expected: %@; Actual: %@", ba1, ba2);
}

- (void)testCopy {
	
    BABitArray *ba1 = [BABitArray bitArray64];
    BABitArray *ba2 = [[ba1 copy] autorelease];
    
    STAssertEqualObjects(ba1, ba2, @"BABitArray copy equality test failed");
    
    [ba2 setBit:63];
    
    STAssertFalse([ba1 isEqual:ba2], @"BABitArray copy modify inequality test failed");
}

- (void)testEncodeDecode {
    
    BABitArray *ba1 = [BABitArray bitArray64];

    [ba1 setBit:11];
    [ba1 setBit:25];
    [ba1 setRange:NSMakeRange(33, 12)];
    [ba1 setBit:63];
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:ba1];
    BABitArray *ba2 = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    STAssertEqualObjects(ba1, ba2, @"BABitArray encode-decode equality test failed");
}

- (void)testEnumeration {
    
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

@end
