//
//  NSObject+BAIntrospection.h
//  BAFoundation
//
//  Created by Brent Gulanowski on 2015-08-16.
//  Copyright (c) 2015 Marketcircle Inc. All rights reserved.
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

extern NSString *NSStringForBAValueType(BAValueType ivarType);
extern BAValueType BAValueTypeForNSString(NSString *string);

extern BAValueType BAValueTypeForEncoding(NSString *encoding);
extern BAValueType BAValueTypeForClass(Class class);
extern NSString *BAValueTypeNameForEncoding(NSString *encoding);
extern NSString *BAValueEncodingForPropertyAttributes(NSString *attributes);

@class BAValueInfo;

@interface NSObject (BAIntrospection)

+ (NSString *)publicClassName;
- (NSString *)publicClassName;

+ (NSArray *)instanceVariableInfo;
+ (NSDictionary *)instanceVariableInfoByName;
+ (NSArray *)instanceVariableInfoForType:(BAValueType)ivarType;

+ (NSArray *)propertyNames;
+ (NSArray *)propertyInfo;
+ (NSArray *)propertyInfoUpToAncestor:(Class)ancestor;
+ (void)logPropertyInfo;

@end

@interface BAValueInfo : NSObject

@property (strong) NSString *name;
@property (strong) NSString *encoding;
@property (strong) NSString *typeName;
@property BAValueType valueType;

- (instancetype)initWithName:(NSString *)name encoding:(NSString *)encoding NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithIvar:(Ivar)ivar;
+ (instancetype)valueInfoWithIvar:(Ivar)ivar;

- (instancetype)initWithProperty:(objc_property_t)property;
+ (instancetype)valueInfoWithProperty:(objc_property_t)property;

@end
