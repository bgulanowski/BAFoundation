//
//  NSObject+BAIntrospection.h
//  BAFoundation
//
//  Created by Brent Gulanowski on 2015-08-16.
//  Copyright (c) 2015 Bored Astronaut. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <objc/runtime.h>

typedef NS_ENUM(NSUInteger, BAValueType) {
    BAValueTypeUndefined,
    BAValueTypeBool,
    BAValueTypeInteger,
    BAValueTypeFloat,
    BAValueTypeCString,
    BAValueTypeCArray, // not supported
    BAValueTypeString, // Objective-C string
    BAValueTypeObject,
    BAValueTypeCollection,
    BAValueTypeClass,
    
    BAValueTypeCount,
};

@class BAValueInfo;

@interface NSObject (BAIntrospection)

+ (NSArray *)ancestors;

+ (NSString *)publicClassName;
- (NSString *)publicClassName;

+ (NSArray *)instanceVariableInfo;
+ (NSDictionary *)instanceVariableInfoByName;
+ (NSArray *)instanceVariableInfoForType:(BAValueType)ivarType;

+ (NSArray *)propertyNames;
+ (NSArray *)propertyInfo;
+ (BAValueInfo *)propertyInfoForName:(NSString *)name;
- (BAValueInfo *)propertyInfoForName:(NSString *)name;
+ (NSDictionary *)propertyInfoByName;
- (NSDictionary *)propertyInfoByName;
+ (NSArray *)propertyInfoUpToAncestor:(Class)ancestor;
+ (void)logPropertyInfo;

@end

@interface BAValueInfo : NSObject

@property (readonly) NSString *name;
@property (readonly) NSString *encoding;
@property (readonly) NSString *typeName;
@property (readonly) BAValueType valueType;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithName:(NSString *)name encoding:(NSString *)encoding NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithIvar:(Ivar)ivar;
+ (instancetype)valueInfoWithIvar:(Ivar)ivar;

- (instancetype)initWithProperty:(objc_property_t)property;
+ (instancetype)valueInfoWithProperty:(objc_property_t)property;

@end

@interface NSObject (BAValueTypes)
+ (BAValueType)valueType;
@end

@interface NSString (BAValueTypes)

+ (NSString *)stringForValueType:(BAValueType)valueType;
- (BAValueType)valueType;

@end
