//
//  BANoiseTest.m
//  BAFoundationTests
//
//  Created by Brent Gulanowski on 2018-05-31.
//  Copyright © 2018 Lichen Labs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <BAFoundation/BANoise.h>

@interface BANoiseTest : XCTestCase

@end

@implementation BANoiseTest

/*
- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}
 */

- (void)testBANoiseEqual {
    
    BANoise *noise = [[BANoise alloc] initWithSeed:8088 octaves:3 persistence:0.5 transform:nil];
    BANoise *other = [[BANoise alloc] initWithSeed:8088 octaves:3 persistence:0.5 transform:nil];
    
    XCTAssertEqualObjects(noise, other);
    XCTAssertTrue([noise isEqualToNoise:other]);
    XCTAssertTrue([noise isEqual:other]);
    XCTAssertFalse([noise isEqual:[NSObject new]]);
}

- (void)testBANoiseHash {
    
    BANoise *noise = [[BANoise alloc] initWithSeed:8088 octaves:3 persistence:0.5 transform:nil];
    BANoise *other = [[BANoise alloc] initWithSeed:8088 octaves:3 persistence:0.5 transform:nil];
    
    XCTAssertEqual([noise hash], [other hash]);
    
    other = [[BANoise alloc] initWithSeed:8089 octaves:3 persistence:0.5 transform:nil];
    XCTAssertNotEqual([noise hash], [other hash]);
    
    other = [[BANoise alloc] initWithSeed:8088 octaves:4 persistence:0.5 transform:nil];
    XCTAssertNotEqual([noise hash], [other hash]);
    
    other = [[BANoise alloc] initWithSeed:8088 octaves:3 persistence:0.51 transform:nil];
    XCTAssertNotEqual([noise hash], [other hash]);
    
    other = [[BANoise alloc] initWithSeed:8088 octaves:3 persistence:0.5 transform:[BANoiseTransform randomTransform]];
    XCTAssertNotEqual([noise hash], [other hash]);
}

@end
