//
//  BANoiseVectorTest.m
//  BAFoundationTests
//
//  Created by Brent Gulanowski on 2018-05-31.
//  Copyright © 2018 Lichen Labs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <BAFoundation/BAFoundation.h>

@interface BANoiseVectorTest : XCTestCase

@end

@implementation BANoiseVectorTest

- (void)testNoiseVectorZero {
    BANoiseVector v = BANoiseVectorZero;
    XCTAssertEqual(v.x, 0);
    XCTAssertEqual(v.y, 0);
    XCTAssertEqual(v.z, 0);
}

@end
