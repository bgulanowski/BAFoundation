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

@end
