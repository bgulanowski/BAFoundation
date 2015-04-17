//
//  BARegionTest.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 2015-04-14.
//  Copyright (c) 2015 Lichen Labs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

#import <BAFoundation/BAFunctions.h>

@interface BARegionTest : XCTestCase

@end

@implementation BARegionTest

- (void)testRandomInteger {
    NSInteger r = BARandomIntegerInRange(0, 0);
    XCTAssertEqual(r, 0L, @"");
    r = BARandomIntegerInRange(-10, 10);
    XCTAssertTrue(r >= -10 && r <= 10, @"");
}

- (void)testPowi {
    NSInteger e = 0;
    NSInteger a = powi(0, 0);
    XCTAssertEqual(a, e, @"");
    e = 1;
    a = powi(1, 0);
    XCTAssertEqual(a, e, @"");
    e = 1;
    a = powi(2, 0);
    XCTAssertEqual(a, e, @"");
    e = 1;
    a = powi(NSIntegerMax, 0);
    XCTAssertEqual(a, e, @"");
    
    e = 1;
    a = powi(1, 1);
    XCTAssertEqual(a, e, @"");
    e = NSIntegerMax;
    a = powi(NSIntegerMax, 1);
    XCTAssertEqual(a, e, @"");

    e = 1;
    a = powi(1, 10);
    XCTAssertEqual(a, e, @"");
}

- (void)testNexPowerOf2 {
    uint32_t e = 0;
    uint32_t a = NextPowerOf2(0);
    XCTAssertEqual(a, e, @"");
    e = 1;
    a = NextPowerOf2(1);
    XCTAssertEqual(a, e, @"");
    e = 4;
    a = NextPowerOf2(3);
    XCTAssertEqual(a, e, @"");
    e = 0;
    a = NextPowerOf2(UINT32_MAX);
    XCTAssertEqual(a, e, @"");
}

- (void)testCountBits {
    BOOL b = NO;
    NSUInteger e = 0;
    NSUInteger a = countBits(&b, 1);
    XCTAssertEqual(a, e, @"");
    b = YES;
    e = 1;
    a = countBits(&b, 1);
    XCTAssertEqual(a, e, @"");
    BOOL ba[8] = { NO, NO, NO, NO, NO, NO, NO, NO };
    e = 0;
    a = countBits(ba, 8);
    XCTAssertEqual(a, e, @"");
    BOOL ya[8] = { YES, YES, YES, YES, YES, YES, YES, YES };
    e = 8;
    a = countBits(ya, 8);
    XCTAssertEqual(a, e, @"");
}

- (void)testBAPoint2Functions {
    BAPoint2 e = { 0, 0 };
    BAPoint2 a = BAPoint2Zero();
    XCTAssertTrue(BAPoint2EqualToPoint2(a, e), @"");
    e = BAPoint2Zero();
    a = BAPoint2Make(0, 0);
    XCTAssertTrue(BAPoint2EqualToPoint2(a, e), @"");
    BAPoint2 b = { 1, 1 };
    XCTAssertFalse(BAPoint2EqualToPoint2(a, b), @"");
}

//- (void)testBARegion2Functions {
//}

@end
