//
//  NSArray+BAFExtensions.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 2016-07-03.
//  Copyright © 2016 Bored Astronaut. All rights reserved.
//

#import "NSArray+BAFExtensions.h"

@implementation NSArray (BAFExtensions)

- (NSArray *)baf_subarrayFromIndex:(NSUInteger)index {
    return [self subarrayWithRange:NSMakeRange(index, self.count - index)];
}

- (NSArray *)baf_subarrayToIndex:(NSUInteger)index {
    return [self subarrayWithRange:NSMakeRange(0, index)];
}

- (id)baf_head {
    return self.firstObject;
}

- (NSArray *)baf_tail {
    return [self baf_subarrayFromIndex:1];
}

- (NSArray *)baf_partition:(NSUInteger)size {
    NSMutableArray *arrays = [NSMutableArray array];
    const NSUInteger count = self.count;
    const NSUInteger i = count < size ? count : size;
    NSUInteger p = 0;
    do {
        [arrays addObject:[self subarrayWithRange:NSMakeRange(p, i)]];
        p += i;
        
    } while (p < count);
    return arrays;
}

- (NSArray *)baf_map:(id (^)(id))block {
    NSMutableArray *results = [NSMutableArray array];
    for (id object in self) {
        [results addObject:block(object)];
    }
    return results;
}

- (id)baf_reduce:(id (^)(id, id))block {
    id result = self.head;
    for (id object in self.tail) {
        result = block(result, object);
    }
    return result;
}

@end
