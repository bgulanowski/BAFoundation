//
//  NSObject+BAIntrospection.h
//  BAFoundation
//
//  Created by Brent Gulanowski on 2015-08-16.
//  Copyright (c) 2015 Marketcircle Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <objc/runtime.h>

typedef NS_ENUM(NSUInteger, BAIvarType) {
    BAIvarTypeUndefined,
    BAIvarTypeBool,
    BAIvarTypeInteger,
    BAIvarTypeFloat,
    BAIvarTypeCString,
    BAIvarTypeCArray, // not supported
    BAIvarTypeString, // Objective-C string
    BAIvarTypeObject,
    BAIvarTypeCollection,
    BAIvarTypeClass,
    
    BAIvarTypeCount,
};

extern NSString *NSStringForBAIvarType(BAIvarType ivarType);
extern BAIvarType BAIvarTypeForNSString(NSString *string);

extern BAIvarType BAIVarTypeForEncoding(const char * encoding);
extern BAIvarType BAIvarTypeForClass(Class class);
extern NSString *BAIvarClassNameForEncoding(const char * encoding);

@class BAIvarInfo;

@interface NSObject (BAIntrospection)

+ (NSString *)publicClassName;
- (NSString *)publicClassName;

+ (NSArray *)instanceVariableInfo;
+ (NSDictionary *)instanceVariableInfoByName;
+ (NSArray *)instanceVariableInfoForType:(BAIvarType)ivarType;

+ (NSArray *)propertyNames;
+ (void)logPropertyInfo;

@end

@interface BAIvarInfo : NSObject

@property (strong) NSString *name;
@property (strong) NSString *encoding;
@property (strong) NSString *objectClassName;
@property BAIvarType type;

- (instancetype)initWithIvar:(Ivar)ivar;
+ (instancetype)ivarInfoWithIvar:(Ivar)ivar;

@end

@interface BAPropertyInfo : NSObject

@property (strong) NSString *name;
@property (strong) NSString *encoding;
@property (strong) NSString *valueClassName;
//@property BAProperty

@end
