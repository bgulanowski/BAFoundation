//
//  BASampleArrayTest.m
//  BAFoundationTests
//
//  Created by Brent Gulanowski on 2018-07-20.
//  Copyright © 2018 Lichen Labs. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BASampleArray.h"

@interface BASampleArray (ExposedPrivates)
- (NSUInteger)indexForCoordinates:(NSUInteger *)coordinates;
@end

@interface BASampleArrayTest : XCTestCase

@end

@implementation BASampleArrayTest {
    NSUInteger values[4];
}

- (instancetype)initWithInvocation:(NSInvocation *)invocation {
    self = [super initWithInvocation:invocation];
    if (self) {
        values[0] = NSUIntegerMax / 973721 + 323 * 435;
        values[1] = NSUIntegerMax - 37 * 91 * 103;
        values[2] = (NSUInteger)INT_MAX * 777;
        values[3] = (1 << 23) - 1;
    }
    return self;
}

- (void)testCreate {
    BASampleArray *sa = [[BASampleArray alloc] initWithPower:2 order:2 size:sizeof(NSUInteger)];
    XCTAssertEqual(sa.power, 2);
    XCTAssertEqual(sa.order, 2);
    NSUInteger expectedCount = 2 * 2; // 2^2
    XCTAssertEqual(sa.count, expectedCount);
    XCTAssertEqual(sa.length, sizeof(NSUInteger) * 2 * 2);
}

- (void)testCreatePage {
    BASampleArray *sa = [BASampleArray page];
    XCTAssertEqual(sa.power, 2);
    XCTAssertEqual(sa.order, 32);
    NSUInteger expectedCount = 32 * 32; // 32^2
    XCTAssertEqual(sa.count, expectedCount);
    XCTAssertEqual(sa.length, expectedCount * sizeof(UInt32));
}

- (void)testCreateBlock {
    BASampleArray *sa = [BASampleArray block];
    XCTAssertEqual(sa.power, 3);
    XCTAssertEqual(sa.order, 32);
    NSUInteger expectedCount = 32 * 32 * 32; // 32^3
    XCTAssertEqual(sa.length, expectedCount * sizeof(UInt32));
}

- (void)testDataLength {
    BASampleArray *sa = [[BASampleArray alloc] initWithPower:2 order:2 size:sizeof(NSUInteger)];
    NSUInteger expectedLength = sizeof(NSUInteger) * 2 * 2;
    XCTAssertEqual(sa.data.length, expectedLength);
}

- (void)testSetGetAtIndex {
    const NSUInteger value = NSUIntegerMax / 179 * 23; // a varied string of bits
    BASampleArray *sa = [[BASampleArray alloc] initWithPower:2 order:2 size:sizeof(NSUInteger)];
    [sa setSample:(UInt8 *)&value atIndex:0];
    NSUInteger actual;
    [sa sample:(UInt8 *)&actual atIndex:0];
    XCTAssertEqual(actual, value);
}

- (void)testMultipleSetGet {
    BASampleArray *sa = [[BASampleArray alloc] initWithPower:2 order:2 size:sizeof(NSUInteger)];
    [sa setSample:(UInt8 *)&values[0] atIndex:0];
    [sa setSample:(UInt8 *)&values[1] atIndex:1];
    [sa setSample:(UInt8 *)&values[2] atIndex:2];
    [sa setSample:(UInt8 *)&values[3] atIndex:3];
    
    NSUInteger actual;
    [sa sample:(UInt8 *)&actual atIndex:0];
    XCTAssertEqual(actual, values[0]);
    [sa sample:(UInt8 *)&actual atIndex:1];
    XCTAssertEqual(actual, values[1]);
    [sa sample:(UInt8 *)&actual atIndex:2];
    XCTAssertEqual(actual, values[2]);
    [sa sample:(UInt8 *)&actual atIndex:3];
    XCTAssertEqual(actual, values[3]);
}

- (void)testRange {
    BASampleArray *sa = [[BASampleArray alloc] initWithPower:2 order:2 size:sizeof(NSUInteger)];
    [sa writeSamples:(UInt8 *)values range:NSMakeRange(0, 4)];
    NSUInteger actual[4];
    [sa readSamples:(UInt8 *)actual range:NSMakeRange(0, 4)];
    XCTAssertEqual(actual[0], values[0]);
    XCTAssertEqual(actual[1], values[1]);
    XCTAssertEqual(actual[2], values[2]);
    XCTAssertEqual(actual[3], values[3]);
}

- (void)testData {
    BASampleArray *sa = [[BASampleArray alloc] initWithPower:2 order:2 size:sizeof(NSUInteger)];
    [sa writeSamples:(UInt8 *)values range:NSMakeRange(0, 4)];
    
    NSData *expected = [NSData dataWithBytes:values length:sizeof(NSUInteger) * 4];
    XCTAssertEqualObjects(sa.data, expected);
}

- (void)testCoordinates {
    
    const NSUInteger order = 8;
    const NSUInteger A = (1 << 29) / 493;
    const NSUInteger B = (1 << 25) / 79 * 11;
    
    BASampleArray *sa = [[BASampleArray alloc] initWithPower:2 order:order size:sizeof(NSUInteger)];
    
#define VALUE(_index) ( A * _index + B )
    
    // Write and immediately check each value
    for (NSUInteger i = 0; i < order; ++i) {
        for (NSUInteger j = 0; j < order; ++j) {
            NSUInteger coords[2] = { j, i };
            NSUInteger index = i * order + j;
            XCTAssertEqual([sa indexForCoordinates:coords], index);
            NSUInteger value = VALUE(index);
            [sa setSample:(UInt8 *)&value atCoordinates:(NSUInteger *)coords];
            NSUInteger actual;
            [sa sample:(UInt8 *)&actual atCoordinates:(NSUInteger *)coords];
            XCTAssertEqual(actual, value);
        }
    }

    // The check all values
    for (NSUInteger i = 0; i < order; ++i) {
        for (NSUInteger j = 0; j < order; ++j) {
            NSUInteger coords[2] = { j, i };
            NSUInteger index = i * order + j;
            NSUInteger value = VALUE(index);
            NSUInteger actual;
            [sa sample:(UInt8 *)&actual atCoordinates:(NSUInteger *)coords];
            XCTAssertEqual(actual, value);
        }
    }
}

@end
