//
//  NSDictionary+BAFExtensions.h
//  BAFoundation
//
//  Created by Brent Gulanowski on 2016-07-03.
//  Copyright © 2016 Bored Astronaut. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BAKeyValuePair;

@interface NSDictionary (BAFExtensions)

- (NSDictionary *)baf_map:(BAKeyValuePair *(^)(id<NSCopying>, id))block;
- (NSDictionary *)baf_mapKeys:(id<NSCopying>(^)(id<NSCopying>))block;
- (NSDictionary *)baf_mapValues:(id(^)(id))block;

@end
