//
//  NSDictionary+BAFExtensions.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 2016-07-03.
//  Copyright © 2016 Bored Astronaut. All rights reserved.
//

#import "NSDictionary+BAFExtensions.h"
#import "BAKeyValuePair.h"

@implementation NSDictionary (BAFExtensions)

- (NSDictionary *)baf_map:(BAKeyValuePair*(^)(id<NSCopying>, id))block {
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    for (id<NSCopying>key in self) {
        BAKeyValuePair *kvp = block(key, self[key]);
        results[kvp.key] = kvp.value;
    }
    return results;
}

- (NSDictionary *)baf_mapKeys:(id<NSCopying> (^)(id<NSCopying>))block {
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    for (id<NSCopying>key in self) {
        results[block(key)] = self[key];
    }
    return results;
}

- (NSDictionary *)baf_mapValues:(id(^)(id<NSCopying>, id))block {
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    for (id<NSCopying>key in self) {
        results[key] = block(key, self[key]);
    }
    return results;
}

@end
