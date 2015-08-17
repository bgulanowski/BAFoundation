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

extern BAValueType BAIVarTypeForEncoding(const char * encoding);
extern BAValueType BAValueTypeForClass(Class class);
extern NSString *BAIvarClassNameForEncoding(const char * encoding);

@class BAIvarInfo;

@interface NSObject (BAIntrospection)

+ (NSString *)publicClassName;
- (NSString *)publicClassName;

+ (NSArray *)instanceVariableInfo;
+ (NSDictionary *)instanceVariableInfoByName;
+ (NSArray *)instanceVariableInfoForType:(BAValueType)ivarType;

+ (NSArray *)propertyNames;
+ (void)logPropertyInfo;

@end

@interface BAIvarInfo : NSObject

@property (strong) NSString *name;
@property (strong) NSString *encoding;
@property (strong) NSString *objectClassName;
@property BAValueType valueType;

- (instancetype)initWithIvar:(Ivar)ivar;
+ (instancetype)ivarInfoWithIvar:(Ivar)ivar;

@end

@interface BAPropertyInfo : NSObject

@property (strong) NSString *name;
@property (strong) NSString *encoding;
@property (strong) NSString *valueClassName;
//@property BAProperty

@end
