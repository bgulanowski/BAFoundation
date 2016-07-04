//
//  BATestObject.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 2016-07-04.
//  Copyright © 2016 Lichen Labs. All rights reserved.
//

#import "BATestObject.h"
#import <BAFoundation/BAFoundation.h>

#define SelectorString(sel_) (NSStringFromSelector(@selector(sel_)))

@implementation BATestObject

+(Class)baf_classForCollectionProperty:(NSString *)propertyName
{
    static NSDictionary *map;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{
                SelectorString(array) : [NSString class],
                SelectorString(set)   : [NSNumber class],
                SelectorString(orderedSet) : [NSDate class],
                                };
    });
    return map[propertyName];
}

@end
