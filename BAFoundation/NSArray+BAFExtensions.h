//
//  NSArray+BAFExtensions.h
//  BAFoundation
//
//  Created by Brent Gulanowski on 2016-07-03.
//  Copyright © 2016 Bored Astronaut. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (BAFExtensions)

@property (nonatomic, readonly, getter=baf_head) id head;
@property (nonatomic, readonly, getter=baf_tail) NSArray *tail;

- (NSArray *)baf_subarrayToIndex:(NSUInteger)index;
- (NSArray *)baf_subarrayFromIndex:(NSUInteger)index;

- (NSArray *)baf_partition:(NSUInteger)size;
- (NSArray *)baf_map:(id(^)(id))block;
- (id)baf_reduce:(id(^)(id, id))block;

@end
