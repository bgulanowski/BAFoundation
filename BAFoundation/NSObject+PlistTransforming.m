//
//  NSObject+PlistTransforming.m
//  Cavebot
//
//  Created by Brent Gulanowski on 12-08-29.
//  Copyright (c) 2012 Lichen Labs. All rights reserved.
//

#import "NSObject+PlistTransforming.h"
#import "NSObject+BAIntrospection.h"
#import "NSArray+BAFExtensions.h"
#import "NSDictionary+BAFExtensions.h"
#import "BAKeyValuePair.h"

@interface BAValueInfo (BAFPlistTransforming)
- (Class)baf_valueClass;
@end

@protocol BAFCollection <NSObject>
+ (instancetype)baf_objectForPropertyList:(NSArray *)propertyList contentClass:(Class)cls;
@end

@interface NSArray (BAFPlistTransforming)<BAFCollection>
@end

@interface NSSet (BAFPlistTransforming)<BAFCollection>
@end

@interface NSOrderedSet (BAFPlistTransforming)<BAFCollection>
@end

#pragma mark -

@implementation NSObject (BAFPlistTransforming)

- (id)baf_propertyListRepresentation {
    return [[self dictionaryWithValuesForKeys:self.class.propertyNames] baf_propertyListRepresentation];
}

- (instancetype)baf_initWithDictionaryOfValuesForKeys:(NSDictionary *)dictionary NS_RETURNS_RETAINED {
    if ((self = [self init])) {
        [self setValuesForKeysWithDictionary:dictionary];
    }
    return self;
}

+ (instancetype)baf_objectForPropertyList:(id)propertyList {
    return [[[self alloc] baf_initWithDictionaryOfValuesForKeys:[propertyList baf_mapValues:^(NSString *key, id propertyList) {
        return [self baf_valueForKey:key propertyList:propertyList];
    }]] autorelease];
}

+ (id)baf_valueForKey:(NSString *)key propertyList:(id)propertyList {
    Class cls = [self baf_classForProperty:key];
    if ([cls conformsToProtocol:@protocol(BAFCollection)]) {
        return [cls baf_objectForPropertyList:propertyList contentClass:[self baf_contentClassForCollectionKey:key]];
    }
    else {
        return [cls baf_objectForPropertyList:propertyList];
    }
}

+ (NSArray *)baf_objectsForPropertyList:(NSArray *)propertyList {
    return [propertyList baf_map:^id(id propertyList) {
        return [self baf_objectForPropertyList:propertyList];
    }];
}

+ (Class)baf_classForProperty:(NSString *)name {
    return [[self propertyInfoForName:name] baf_valueClass];
}

+ (Class)baf_contentClassForCollectionKey:(NSString *)key {
    [NSException raise:@"BAFUnimplementedMethodException" format:@"Class `%@` must override `%@`", [self publicClassName], NSStringFromSelector(_cmd)];
    return Nil;
}

@end

#pragma mark -

@implementation NSNumber (BAFPlistTransforming)
- (id)baf_propertyListRepresentation { return self; }
+ (instancetype)baf_objectForPropertyList:(id)propertyList { return propertyList; }
@end

@implementation NSString (BAFPlistTransforming)
- (id)baf_propertyListRepresentation { return self; }
+ (instancetype)baf_objectForPropertyList:(id)propertyList { return propertyList; }
@end

@implementation NSData (BAFPlistTransforming)
- (id)baf_propertyListRepresentation { return self; }
+ (instancetype)baf_objectForPropertyList:(id)propertyList { return propertyList; }
@end

@implementation NSDate (BAFPlistTransforming)
- (id)baf_propertyListRepresentation { return self; }
+ (instancetype)baf_objectForPropertyList:(id)propertyList { return propertyList; }
@end

#pragma mark -

@implementation NSArray (BAFPlistTransforming)

+ (instancetype)baf_objectForPropertyList:(NSArray *)propertyList contentClass:(Class)cls {
    return [propertyList baf_mapForClass:cls];
}

- (id)baf_propertyListRepresentation {
    return [self valueForKey:NSStringFromSelector(_cmd)];
}

- (instancetype)baf_mapForClass:(Class)cls {
    return [self baf_map:^(id propertyList) {
        return [cls baf_objectForPropertyList:propertyList];
    }];
}

@end

#pragma mark -

@implementation NSSet (BAFPlistTransforming)

+ (instancetype)baf_objectForPropertyList:(NSArray *)propertyList contentClass:(Class)cls {
    return [[[self alloc] initWithArray:[propertyList baf_mapForClass:cls]] autorelease];
}

- (id)baf_propertyListRepresentation {
    return self.allObjects.propertyListRepresentation;
}

@end

#pragma mark -

@implementation NSOrderedSet (BAFPlistTransforming)

+ (instancetype)baf_objectForPropertyList:(NSArray *)propertyList contentClass:(Class)cls {
    return [[[self alloc] initWithArray:[propertyList baf_mapForClass:cls]] autorelease];
}

- (id)baf_propertyListRepresentation {
    return self.array.propertyListRepresentation;
}

@end

#pragma mark -

@implementation NSDictionary (BAFPlistTransforming)

- (id)baf_propertyListRepresentation {
    return [NSDictionary dictionaryWithObjects:self.allValues.propertyListRepresentation forKeys:self.allKeys];
}

- (instancetype)initWithPropertyList:(id)propertyList class:(Class)cls {
    return [self initWithDictionary:[propertyList baf_mapForClass:cls]];
}

- (NSDictionary *)baf_mapForClass:(Class)class {
    return [self baf_map:^(NSString *key, id propertyList) {
        return [BAKeyValuePair keyValuePairWithKey:key value:[class baf_valueForKey:key propertyList:propertyList]];
    }];
}

@end

#pragma mark -

@implementation BAValueInfo (BAFPlistTransforming)

- (Class)baf_valueClass {
    return NSClassFromString(self.typeName);
}

@end
