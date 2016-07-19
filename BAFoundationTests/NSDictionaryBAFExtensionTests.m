//
//  NSArrayBAFExtensionTests.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 2016-07-03.
//  Copyright © 2016 Lichen Labs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <BAFoundation/BAFoundation.h>

@interface NSDictionaryBAFExtensionTests : XCTestCase

@end

@implementation NSDictionaryBAFExtensionTests

- (void)testMap {
    NSDictionary *d = @{
                        @1 : @"1",
                        @2 : @"2"
                        };
    NSDictionary *a = [d baf_map:^BAKeyValuePair *(NSNumber *key, NSString *value) {
        return [BAKeyValuePair keyValuePairWithKey:value value:[NSNumber numberWithInteger:([key integerValue] * 10)]];
    }];
    NSDictionary *e = @{
                        @"1" : @10,
                        @"2" : @20
                        };
    XCTAssertEqualObjects(e, a);
}

- (void)testMapKeys {
    
    NSDictionary *d = @{
                        @1 : @"one",
                        @2 : @"two"
                        };
    NSDictionary *e = @{
                        @"1" : @"one",
                        @"2" : @"two"
                        };
    NSDictionary *a = [d baf_mapKeys:^(NSNumber *key) {
        return key.stringValue;
    }];
    XCTAssertEqualObjects(e, a);
}

- (void)testMapValues {
    NSDictionary *d = @{
                        @"one" : @1,
                        @"two" : @2
                        };
    NSDictionary *e = @{
                        @"one" : @"1",
                        @"two" : @"2"
                        };
    NSDictionary *a = [d baf_mapValues:^(id<NSCopying> key, NSNumber *value) {
        return value.stringValue;
    }];
    XCTAssertEqualObjects(e, a);
}

@end
