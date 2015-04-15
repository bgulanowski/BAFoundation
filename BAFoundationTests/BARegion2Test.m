//
//  BARegion2Test.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 2015-04-14.
//  Copyright (c) 2015 Lichen Labs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SenTestingKit/SenTestingKit.h>

#import <BAFoundation/BAFunctions.h>

@interface BARegion2Test : SenTestCase

@end

@implementation BARegion2Test

- (void)testRandomInteger {
    NSInteger r = BARandomIntegerInRange(0, 0);
    STAssertEquals(r, 0L, @"");
    r = BARandomIntegerInRange(-10, 10);
    STAssertTrue(r >= -10 && r <= 10, @"");
}

- (void)testPowi {
    NSInteger e = 0;
    NSInteger a = powi(0, 0);
    STAssertEquals(a, e, @"");
    e = 1;
    a = powi(1, 0);
    STAssertEquals(a, e, @"");
    e = 1;
    a = powi(2, 0);
    STAssertEquals(a, e, @"");
    e = 1;
    a = powi(NSIntegerMax, 0);
    STAssertEquals(a, e, @"");
    
    e = 1;
    a = powi(1, 1);
    STAssertEquals(a, e, @"");
    e = NSIntegerMax;
    a = powi(NSIntegerMax, 1);
    STAssertEquals(a, e, @"");

    e = 1;
    a = powi(1, 10);
    STAssertEquals(a, e, @"");
}

- (void)testNexPowerOf2 {
    uint32_t e = 0;
    uint32_t a = NextPowerOf2(0);
    STAssertEquals(a, e, @"");
    e = 1;
    a = NextPowerOf2(1);
    STAssertEquals(a, e, @"");
    e = 4;
    a = NextPowerOf2(3);
    STAssertEquals(a, e, @"");
    e = 0;
    a = NextPowerOf2(UINT32_MAX);
    STAssertEquals(a, e, @"");
}

- (void)testCountBits {
    BOOL b = NO;
    NSUInteger e = 0;
    NSUInteger a = countBits(&b, 1);
    STAssertEquals(a, e, @"");
    b = YES;
    e = 1;
    a = countBits(&b, 1);
    STAssertEquals(a, e, @"");
    BOOL ba[8] = { NO, NO, NO, NO, NO, NO, NO, NO };
    e = 0;
    a = countBits(ba, 8);
    STAssertEquals(a, e, @"");
    BOOL ya[8] = { YES, YES, YES, YES, YES, YES, YES, YES };
    e = 8;
    a = countBits(ya, 8);
    STAssertEquals(a, e, @"");
}

- (void)testBAPoint2Functions {
    BAPoint2 e = { 0, 0 };
    BAPoint2 a = BAPoint2Zero();
    STAssertEquals(a, e, @"");
    e = BAPoint2Zero();
    a = BAPoint2Make(0, 0);
    STAssertEquals(a, e, @"");
    STAssertTrue(BAPoint2EqualToPoint2(a, e), @"");
    BAPoint2 b = { 1, 1 };
    STAssertFalse(BAPoint2EqualToPoint2(a, b), @"");
}

- (void)testBARegion2Functions {
    STFail(@"unimplemented tests");
}

@end
