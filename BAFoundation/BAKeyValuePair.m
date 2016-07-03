//
//  BAKeyValuePair.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 2016-07-03.
//  Copyright © 2016 Bored Astronaut. All rights reserved.
//

#import "BAKeyValuePair.h"

@implementation BAKeyValuePair

- (instancetype)initWithKey:(NSObject<NSCopying> *)key value:(id)value {
    self = [super init];
    if (self) {
        _key = key;
        _value = value;
    }
    return self;
}

+ (instancetype)keyValuePairWithKey:(NSObject<NSCopying> *)key value:(id)value {
    return [[self alloc] initWithKey:key value:value];
}

#pragma mark - NSObject

- (NSUInteger)hash {
    return [_value hash];
}

- (BOOL)isEqual:(BAKeyValuePair *)object {
    return [super isEqual:object] || ([object isKindOfClass:[BAKeyValuePair class]] && [(NSObject *)_key isEqual:object.key] && [_value isEqual:object.value]);
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    return [BAKeyValuePair keyValuePairWithKey:[(NSObject *)_key copy] value:_value];
}

@end
