//
//  BAKeyValuePairTests.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 2016-07-03.
//  Copyright © 2016 Lichen Labs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <BAFoundation/BAFoundation.h>

@interface BAKeyValuePairTests : XCTestCase

@end

@implementation BAKeyValuePairTests

- (void)testCreation {
    
    BAKeyValuePair *a = [[BAKeyValuePair alloc] initWithKey:@"1" value:@"one"];
    
    XCTAssertEqualObjects(@"1", a.key);
    XCTAssertEqualObjects(@"one", a.value);
    
    BAKeyValuePair *b = [BAKeyValuePair keyValuePairWithKey:@"1" value:@"one"];
    XCTAssertEqualObjects(@"1", b.key);
    XCTAssertEqualObjects(@"one", b.value);
    
    XCTAssertEqualObjects(a, b);
}

@end
