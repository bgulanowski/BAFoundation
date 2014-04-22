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
+ (NSString *)guessedDefaultSortDescriptor;
@end

@implementation NSEntityDescription (BAAdditions)

+ (void)load {
    sortKeyCache = [[NSMutableDictionary alloc] init];
}

- (NSString *)defaultSortKey {
    
    NSString *cacheKey = [self name];
    id sortKey = sortKeyCache[cacheKey];
    
    if (sortKey == [NSNull null]) {
        return nil;
    }
    
    if (!sortKey) {
        sortKey = [[self userInfo] objectForKey:@"sortKey"];
    }
    
    if (!sortKey) {
        Class class = NSClassFromString([self managedObjectClassName]);
        sortKey = [class defaultSortKey];
    }
    
    if (!sortKey) {
        NSMutableSet *attributeNames = [NSMutableSet setWithArray:[[self attributesByName] allKeys]];
        [attributeNames intersectSet:sortingKeys];
        sortKey = [attributeNames anyObject] ?: [NSNull null];
    }
    
    if (!sortKey) {
        sortKey = [NSManagedObject guessedDefaultSortDescriptor];
    }
    
    return sortKey;
}

- (NSArray *)defaultSortDescriptors {
    
    Class class = NSClassFromString([self managedObjectClassName]);
    NSString *key = [self defaultSortKey] ?: [class defaultSortKey];
    
    if(key)
        return [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:key ascending:[class defaultSortAscending]]];
    else
        return nil;
}

- (NSFetchRequest *)defaultFetchRequest {
    NSFetchRequest *fetch = [[NSFetchRequest alloc] initWithEntityName:[self name]];
    fetch.sortDescriptors = [self defaultSortDescriptors];
    return fetch;
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

+ (NSString *)guessedDefaultSortDescriptor {
    
    NSString *className = NSStringFromClass(self);
    id sortKey = [sortKeyCache objectForKey:className];
    Class class = self;
    
    if (nil == sortKey) {
        
        while (class != [NSManagedObject class] && sortKey == nil) {
            NSMutableSet *propertyNames = [[[class ba_propertyNames] mutableCopy] autorelease];
            [propertyNames intersectSet:sortingKeys];
            sortKey = [propertyNames anyObject];
            class = [self superclass];
        }
        
        sortKeyCache[className] = sortKey ?: [NSNull null];
    }
    
    return sortKey;
}

@end