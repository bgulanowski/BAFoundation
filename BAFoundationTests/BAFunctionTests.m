//
//  BAFunctionTests.m
//  BAFoundationTests
//
//  Created by Brent Gulanowski on 2018-05-31.
//  Copyright © 2018 Lichen Labs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <BAFoundation/BAFoundation.h>

@interface BAFunctionTests : XCTestCase

@end

@implementation BAFunctionTests

- (void)testBANEQ {
    
    XCTAssertFalse(BANEQ(0, 0));
    XCTAssertFalse(BANEQ(1, 1));
    XCTAssertFalse(BANEQ(-1, -1));

    XCTAssertTrue(BANEQ(0, 1));
    XCTAssertTrue(BANEQ(0, -1));
    
    XCTAssertTrue(BANEQ(pow(2, 16), pow(2, 16) - 1.0));
    XCTAssertTrue(BANEQ(pow(2, 32), pow(2, 32) - 1.0));
    XCTAssertTrue(BANEQ(pow(2, 48), pow(2, 48) - 1.0));
    XCTAssertTrue(BANEQ(pow(2, 52), pow(2, 52) - 1.0));
    XCTAssertTrue(BANEQ(pow(2, 53), pow(2, 53) - 1.0));
    
    XCTAssertFalse(BANEQ(pow(2, 54), pow(2, 54) - 1.0));
    XCTAssertFalse(BANEQ(pow(2, 56), pow(2, 56) - 1.0));
    XCTAssertFalse(BANEQ(pow(2, 64), pow(2, 64) - 1.0));
}

- (void)testBAHash {
    
    char *a = "a";
    char *b = "b";
    
    char *copy = malloc(2);
    strncpy(copy, a, 2);
    
    XCTAssertEqual(BAHash(a, (unsigned)strlen(a)), BAHash(copy, (unsigned)strlen(copy)));
    XCTAssertNotEqual(BAHash(a, (unsigned)strlen(a)), BAHash(b, (unsigned)strlen(b)));
    
    NSObject *obj1 = [NSObject new];
    NSObject *obj2 = [NSObject new];
    
    unsigned instance_size = (unsigned)class_getInstanceSize([NSObject class]);
    
    XCTAssertEqual(BAHash((char *)obj1, instance_size), BAHash((char *)obj2, instance_size));
}

@end
