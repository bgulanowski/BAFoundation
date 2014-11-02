//
//  NSEntityDescription+BAAdditions.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 2014-04-21.
//  Copyright (c) 2014 Marketcircle Inc. All rights reserved.
//

#import "NSEntityDescription+BAAdditions.h"

#import <BAFoundation/NSManagedObject+BAAdditions.h>

#include <objc/runtime.h>


static NSMutableDictionary *sortKeyCache;

// See NSManagedObject+BAAdditions.m -- this is a private implementation detail
extern NSSet *sortingKeys;

@interface NSManagedObject (BAAdditionsForEntity)
+ (NSString *)guessedDefaultSortKey;
@end

@implementation NSEntityDescription (BAAdditions)

+ (void)load {
    sortKeyCache = [[NSMutableDictionary alloc] init];
}

- (id)findDefaultSortKey {
    
    id sortKey = [[self userInfo] objectForKey:@"sortKey"];
    
    if (!sortKey) {
        sortKey = [NSClassFromString([self managedObjectClassName]) defaultSortKey];
    }
    if (!sortKey) {
        NSMutableSet *attributeNames = [NSMutableSet setWithArray:[[self attributesByName] allKeys]];
        [attributeNames intersectSet:sortingKeys];
        sortKey = [attributeNames anyObject];
    }
    if (!sortKey) {
        sortKey = [NSManagedObject guessedDefaultSortKey];
    }
    
    return sortKey;
}

- (NSString *)defaultSortKey {
    
    id cacheKey = [self name];
    id sortKey = sortKeyCache[cacheKey];
    
    if (!sortKey) {
        sortKeyCache[cacheKey] = sortKey = [self findDefaultSortKey] ?: [NSNull null];
    }
    
    return (sortKey == [NSNull null]) ? nil : sortKey;
}

- (NSArray *)defaultSortDescriptors {
    
    Class class = NSClassFromString([self managedObjectClassName]);
    NSString *key = [self defaultSortKey];
    
    if(key) {
        return [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:key ascending:[class defaultSortAscending]]];
    }
    return nil;
}

- (NSFetchRequest *)defaultFetchRequest {
    NSFetchRequest *fetch = [[NSFetchRequest alloc] initWithEntityName:[self name]];
    fetch.sortDescriptors = [self defaultSortDescriptors];
    return [fetch autorelease];
}

@end


@implementation NSManagedObject (BAAdditionsForEntity)

+ (NSSet *)ba_propertyNames {
    
    NSMutableSet *propertyNames = [NSMutableSet set];
    
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList(self, &count);
    
    for (NSUInteger i=0; i<count; ++i) {
        [propertyNames addObject:[NSString stringWithCString:property_getName(properties[i]) encoding:NSUTF8StringEncoding]];
    }
    free(properties);
    
    return propertyNames;
}

+ (NSString *)guessedDefaultSortKey {
    
    id sortKey = nil;
    Class class = self;
    
    if (nil == sortKey) {
        
        while (class != [NSManagedObject class] && sortKey == nil) {
            NSMutableSet *propertyNames = [[[class ba_propertyNames] mutableCopy] autorelease];
            [propertyNames intersectSet:sortingKeys];
            sortKey = [propertyNames anyObject];
            class = [self superclass];
        }
    }
    
    return sortKey;
}

@end