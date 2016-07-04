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

- (id)baf_valueForPropertyList:(id)propertyList source:(Class)class;
- (Class)baf_valueClass;

@end

#pragma mark -

@implementation NSObject (BAFPlistTransforming)

- (id)baf_propertyListRepresentation {
    return [[self dictionaryWithValuesForKeys:self.class.propertyNames] baf_propertyListRepresentation];
}

- (instancetype)initWithPropertyList:(NSDictionary *)propertyList class:(Class)cls {
    self = [self init];
    if (self) {
        [self setValuesForKeysWithDictionary:[propertyList baf_mapForClass:self.class]];
    }
    return self;
}

+ (Class)baf_classForCollectionProperty:(NSString *)propertyName {
    [NSException raise:@"BAFUnimplementedMethodException" format:@"Class `%@` must override `%@`", [self publicClassName], NSStringFromSelector(_cmd)];
    return Nil;
}

@end

#pragma mark -

@implementation NSNumber (BAFPlistTransforming)
- (id)baf_propertyListRepresentation { return self; }
- (instancetype)initWithPropertyList:(id)propertyList { return [self init]; }
@end

@implementation NSString (BAFPlistTransforming)
- (id)baf_propertyListRepresentation { return self; }
- (instancetype)initWithPropertyList:(id)propertyList { return [self init]; }
@end

@implementation NSData (BAFPlistTransforming)
- (id)baf_propertyListRepresentation { return self; }
- (instancetype)initWithPropertyList:(id)propertyList { return [self init]; }
@end

@implementation NSDate (BAFPlistTransforming)
- (id)baf_propertyListRepresentation { return self; }
- (instancetype)initWithPropertyList:(id)propertyList { return [self init]; }
@end

#pragma mark -

@implementation NSArray (BAFPlistTransforming)

- (id)baf_propertyListRepresentation {
    return [self valueForKey:NSStringFromSelector(_cmd)];
}

- (instancetype)initWithPropertyList:(NSArray *)propertyList class:(Class)cls {
    return [self initWithArray:[propertyList baf_mapForClass:cls]];
}

- (instancetype)baf_mapForClass:(Class)cls {
    return [self baf_map:^(id propertyList) {
        return [[cls alloc] initWithPropertyList:propertyList];
    }];
}

@end

#pragma mark -

@implementation NSSet (BAFPlistTransforming)

- (id)baf_propertyListRepresentation {
    return self.allObjects.propertyListRepresentation;
}

- (instancetype)initWithPropertyList:(NSArray *)propertyList class:(Class)cls {
    return [self initWithArray:[propertyList baf_mapForClass:cls]];
}

@end

#pragma mark -

@implementation NSOrderedSet (BAFPlistTransforming)

- (id)baf_propertyListRepresentation {
    return self.array.propertyListRepresentation;
}

- (instancetype)initWithPropertyList:(NSArray *)propertyList class:(Class)cls {
    return [self initWithArray:[propertyList baf_mapForClass:cls]];
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
    return [self baf_map:^(NSString *key, id value) {
        return [BAKeyValuePair keyValuePairWithKey:key value:[[class propertyInfoForName:key] baf_valueForPropertyList:value source:class]];
    }];
}

@end

#pragma mark -

@implementation BAValueInfo (BAFPlistTransforming)

- (id)baf_valueForPropertyList:(id)propertyList source:(Class)cls {
    return [[[self baf_valueClass] alloc] initWithPropertyList:propertyList class:cls];
}

- (Class)baf_valueClass {
    return NSClassFromString(self.typeName);
}

@end
