//
//  NSObjectBAIntrospectionTests.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 2016-07-03.
//  Copyright © 2016 Lichen Labs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <BAFoundation/BAFoundation.h>

@interface NSObjectBAIntrospectionTests : XCTestCase

@end

@implementation NSObjectBAIntrospectionTests

- (void)testValueInfo {
    
    NSString *encoding = [NSString stringWithCString:@encode(id) encoding:NSASCIIStringEncoding];
    BAValueInfo *v = [[BAValueInfo alloc] initWithName:@"object" encoding:encoding];
    XCTAssertEqualObjects(@"object", v.name);
    XCTAssertEqualObjects(@"id", v.typeName);
    XCTAssertEqual(BAValueTypeObject, v.valueType);
    
//    encoding = [NSString stringWithCString:@encode(NSURL) encoding:NSASCIIStringEncoding];
//    v = [[BAValueInfo alloc] initWithName:@"object" encoding:encoding];
//    XCTAssertEqualObjects(@"NSURL", v.typeName);
//    XCTAssertEqual(BAValueTypeObject, v.valueType);
    
    objc_property_t property = class_getProperty([NSURLRequest class], "URL");
    
    v = [BAValueInfo valueInfoWithProperty:property];
    
    XCTAssertEqualObjects(@"host", v.name);
    XCTAssertEqualObjects(@"NSString", v.typeName);
    XCTAssertEqual(BAValueTypeString, v.valueType);
}

@end
