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

@interface BAIntrospectionTest : NSObject

@property _Bool c99Boolean;
@property BOOL objcBoolean;
@property char character;
@property NSInteger integer;
@property CGFloat cgFloat;
@property char *cString;

@property (strong) id object;
@property (strong) NSDate *date;
@property (strong) NSData *data;
@property (strong) NSNumber *number;
@property (strong) NSString *string;

@property (strong) NSArray *array;
@property (strong) NSSet *set;
@property (strong) NSOrderedSet *orderedSet;
@property (strong) NSDictionary *dictionary;

@property Class cls;

@end

@implementation NSObjectBAIntrospectionTests

- (void)testBasicValueInfo {
    
    NSString *encoding = [NSString stringWithCString:@encode(id) encoding:NSASCIIStringEncoding];
    BAValueInfo *v = [[BAValueInfo alloc] initWithName:@"object" encoding:encoding];
    XCTAssertEqualObjects(@"object", v.name);
    XCTAssertEqualObjects(@"id", v.typeName);
    XCTAssertEqual(BAValueTypeUndefined, v.valueType);
    
    v = [NSURLRequest propertyInfoForName:@"URL"];
    XCTAssertEqualObjects(@"URL", v.name);
    XCTAssertEqualObjects(@"NSURL", v.typeName);
    XCTAssertEqual(BAValueTypeObject, v.valueType);
    
    v = [NSURLRequest propertyInfoForName:@"timeoutInterval"];
    XCTAssertNil(v.typeName);
    XCTAssertEqual(BAValueTypeFloat, v.valueType);
    
    v = [NSError propertyInfoForName:@"localizedRecoveryOptions"];
    XCTAssertEqualObjects(@"NSArray", v.typeName);
    XCTAssertEqual(BAValueTypeCollection, v.valueType);
}

#pragma mark - value properties

- (void)testC99BooleanPropertyInfo {
    NSString *propertyName = @"c99Boolean";
    BAValueInfo *v = [BAIntrospectionTest propertyInfoForName:propertyName];
    XCTAssertEqualObjects(propertyName, v.name);
    XCTAssertEqual(BAValueTypeBool, v.valueType);
}

- (void)testObjCBooleanPropertyInfo {
    NSString *propertyName = @"objcBoolean";
    BAValueInfo *v = [BAIntrospectionTest propertyInfoForName:propertyName];
    XCTAssertEqualObjects(propertyName, v.name);
    XCTAssertEqual(BAValueTypeInteger, v.valueType);
}

- (void)testBooleanPropertyInfo {
    NSString *propertyName = @"character";
    BAValueInfo *v = [BAIntrospectionTest propertyInfoForName:propertyName];
    XCTAssertEqualObjects(propertyName, v.name);
    XCTAssertEqual(BAValueTypeInteger, v.valueType);
}

- (void)testIntegerPropertyInfo {
    NSString *propertyName = @"integer";
    BAValueInfo *v = [BAIntrospectionTest propertyInfoForName:propertyName];
    XCTAssertEqualObjects(propertyName, v.name);
    XCTAssertEqual(BAValueTypeInteger, v.valueType);
}

- (void)testFloatPropertyInfo {
    NSString *propertyName = @"cgFloat";
    BAValueInfo *v = [BAIntrospectionTest propertyInfoForName:propertyName];
    XCTAssertEqualObjects(propertyName, v.name);
    XCTAssertEqual(BAValueTypeFloat, v.valueType);
}

#pragma mark - pointer properties

- (void)testCStringPropertyInfo {
    NSString *propertyName = @"cString";
    BAValueInfo *v = [BAIntrospectionTest propertyInfoForName:propertyName];
    XCTAssertEqualObjects(propertyName, v.name);
    XCTAssertEqual(BAValueTypeCString, v.valueType);
}

#pragma mark - object properties

- (void)testObjectPropertyInfo {
    NSString *propertyName = @"object";
    BAValueInfo *v = [BAIntrospectionTest propertyInfoForName:propertyName];
    XCTAssertEqualObjects(propertyName, v.name);
    XCTAssertEqual(BAValueTypeObject, v.valueType);
}

- (void)testDatePropertyInfo {
    NSString *propertyName = @"date";
    BAValueInfo *v = [BAIntrospectionTest propertyInfoForName:propertyName];
    XCTAssertEqualObjects(propertyName, v.name);
    XCTAssertEqualObjects(@"NSDate", v.typeName);
    XCTAssertEqual(BAValueTypeObject, v.valueType);
}

- (void)testDataPropertyInfo {
    NSString *propertyName = @"data";
    BAValueInfo *v = [BAIntrospectionTest propertyInfoForName:propertyName];
    XCTAssertEqualObjects(propertyName, v.name);
    XCTAssertEqualObjects(@"NSData", v.typeName);
    XCTAssertEqual(BAValueTypeObject, v.valueType);
}

- (void)testNumberPropertyInfo {
    NSString *propertyName = @"number";
    BAValueInfo *v = [BAIntrospectionTest propertyInfoForName:propertyName];
    XCTAssertEqualObjects(@"NSNumber", v.typeName);
XCTAssertEqualObjects(propertyName, v.name);
    
    XCTAssertEqual(BAValueTypeObject, v.valueType);
}

- (void)testStringPropertyInfo {
    NSString *propertyName = @"string";
    BAValueInfo *v = [BAIntrospectionTest propertyInfoForName:propertyName];
    XCTAssertEqualObjects(propertyName, v.name);
    XCTAssertEqualObjects(@"NSString", v.typeName);
    XCTAssertEqual(BAValueTypeString, v.valueType);
}

- (void)testSetPropertyInfo {
    NSString *propertyName = @"set";
    BAValueInfo *v = [BAIntrospectionTest propertyInfoForName:propertyName];
    XCTAssertEqualObjects(propertyName, v.name);
    XCTAssertEqualObjects(@"NSSet", v.typeName);
    XCTAssertEqual(BAValueTypeCollection, v.valueType);
}

- (void)testOrderedSetPropertyInfo {
    NSString *propertyName = @"orderedSet";
    BAValueInfo *v = [BAIntrospectionTest propertyInfoForName:propertyName];
    XCTAssertEqualObjects(propertyName, v.name);
    XCTAssertEqualObjects(@"NSOrderedSet", v.typeName);
    XCTAssertEqual(BAValueTypeCollection, v.valueType);
}

- (void)testDictionaryPropertyInfo {
    NSString *propertyName = @"dictionary";
    BAValueInfo *v = [BAIntrospectionTest propertyInfoForName:propertyName];
    XCTAssertEqualObjects(propertyName, v.name);
    XCTAssertEqualObjects(@"NSDictionary", v.typeName);
    XCTAssertEqual(BAValueTypeObject, v.valueType);
}

- (void)testClassPropertyInfo {
    NSString *propertyName = @"cls";
    BAValueInfo *v = [BAIntrospectionTest propertyInfoForName:propertyName];
    XCTAssertEqualObjects(propertyName, v.name);
    XCTAssertEqual(BAValueTypeClass, v.valueType);
}

@end

#pragma mark -

@implementation BAIntrospectionTest
@end
