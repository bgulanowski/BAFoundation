//
//  NSArrayBAFExtensionTests.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 2016-07-03.
//  Copyright © 2016 Lichen Labs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <BAFoundation/BAFoundation.h>

@interface NSArrayBAFExtensionTests : XCTestCase

@end

@implementation NSArrayBAFExtensionTests

- (void)testHead {
    NSArray *array = @[];
    XCTAssertNil(array.head);
    
    array = @[@1];
    XCTAssertEqualObjects(@1, array.head);

    array = @[@1, @2];
    XCTAssertEqualObjects(@1, array.head);
}

- (void)testTail {

    NSArray *array = @[];
    XCTAssertThrows(array.tail);

    array = @[@1];
    XCTAssertEqualObjects(@[], array.tail);
    
    array = @[@1, @2];
    XCTAssertEqualObjects(@[@2], array.tail);
}

- (void)testSubarrayToIndex {
    
    NSArray *array = @[];
    XCTAssertEqualObjects(@[], [array baf_subarrayToIndex:0]);
    XCTAssertThrows([array baf_subarrayToIndex:1]);
    
    array = @[@1];
    XCTAssertEqualObjects(@[], [array baf_subarrayToIndex:0]);
    XCTAssertEqualObjects(@[@1], [array baf_subarrayToIndex:1]);
    
    array = @[@1, @2];
    XCTAssertEqualObjects(@[], [array baf_subarrayToIndex:0]);
    XCTAssertEqualObjects(@[@1], [array baf_subarrayToIndex:1]);
    XCTAssertEqualObjects((@[@1, @2]), [array baf_subarrayToIndex:2]);
}

- (void)testSubarrayFromIndex {
    
    NSArray *array = @[];
    XCTAssertEqualObjects(@[], [array baf_subarrayFromIndex:0]);
    
    array = @[@1];
    XCTAssertEqualObjects(@[@1], [array baf_subarrayFromIndex:0]);
    XCTAssertEqualObjects(@[], [array baf_subarrayFromIndex:1]);
    
    array = @[@1, @2];
    XCTAssertEqualObjects((@[@1, @2]), [array baf_subarrayFromIndex:0]);
    XCTAssertEqualObjects(@[@2], [array baf_subarrayFromIndex:1]);
    XCTAssertEqualObjects(@[], [array baf_subarrayFromIndex:2]);
}

@end
