//
//  NSObject+BAIntrospection.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 2015-08-16.
//  Copyright (c) 2015 Marketcircle Inc. All rights reserved.
//

#import "NSObject+BAIntrospection.h"

static NSMutableDictionary *typeInfoIndex;

static void PrepareTypeNamesAndValues( void );

@interface NSObject (BACompatibility)
- (NSString *)className;
@end

@implementation NSObject (BAIntrospection)

+ (NSString *)publicClassName {
    if ([self respondsToSelector:@selector(className)]) {
        return [self className];
    }
    return NSStringFromClass(self);
}

- (NSString *)publicClassName {
    return [[self class] publicClassName];
}

+ (NSArray *)cachedInstanceVariableInfo {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        typeInfoIndex = [NSMutableDictionary dictionary];
    });
    return typeInfoIndex[[self publicClassName]];
}

+ (NSArray *)createInstanceVariableInfo {
    
    NSMutableArray *typeInfos = [NSMutableArray array];
    
    unsigned int count;
    Ivar *ivars = class_copyIvarList(self, &count);
    
    for (unsigned int index=0; index<count; ++index) {
        [typeInfos addObject:[BAIvarInfo ivarInfoWithIvar:ivars[index]]];
    }
    
    free(ivars);
    
    return typeInfos;
}

+ (NSArray *)instanceVariableInfo {
    
    NSArray *info = [self cachedInstanceVariableInfo];
    
    if (nil == info) {
        typeInfoIndex[[self publicClassName]] = info = [self createInstanceVariableInfo];
    }
    
    return info;
}

+ (NSDictionary *)instanceVariableInfoByName {
    NSArray *info = [self instanceVariableInfo];
    return [NSDictionary dictionaryWithObjects:info forKeys:[info valueForKey:@"name"]];
}

+ (NSArray *)instanceVariableInfoForType:(BAValueType)ivarType {
    return [[self instanceVariableInfo] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type = %td", ivarType]];
}

+ (void)iteratePropertiesWithBlock:(void(^)(objc_property_t))block {
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList(self, &count);
    for (unsigned int i=0; i<count; ++i) {
        block(properties[i]);
    }
    free(properties);
}

+ (NSArray *)propertyNames {
    NSMutableArray *names = [NSMutableArray array];
    [self iteratePropertiesWithBlock:^(objc_property_t property) {
        [names addObject:[NSString stringWithUTF8String:property_getName(property)]];
    }];
    return names;
}

+ (void)logPropertyInfo {
    [self iteratePropertiesWithBlock:^(objc_property_t property) {
        NSLog(@"%s: %s", property_getName(property), property_getAttributes(property));
    }];
}

@end

@implementation BAIvarInfo

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        PrepareTypeNamesAndValues();
    });
}

- (instancetype)initWithIvar:(Ivar)ivar {
    self = [super init];
    if (self) {
        self.name = [NSString stringWithUTF8String:ivar_getName(ivar)];
        const char *encoding = ivar_getTypeEncoding(ivar);
        self.valueType = BAIVarTypeForEncoding(encoding);
        self.objectClassName = BAIvarClassNameForEncoding(encoding);
        // for debugging
        self.encoding = [NSString stringWithUTF8String:encoding];
    }
    return self;
}

- (NSString *)debugDescription {
    
    NSString *detail = nil;
    if (self.valueType == BAValueTypeObject) {
        detail = self.objectClassName;
    }
    else if (self.valueType == BAValueTypeCollection) {
        detail = self.objectClassName;
    }
    else {
        detail = NSStringForBAValueType(self.valueType);
    }

    return [NSString stringWithFormat:@"%@: %@ (%@)", self.name, detail, self.encoding];
}

+ (instancetype)ivarInfoWithIvar:(Ivar)ivar {
    return [[self alloc] initWithIvar:ivar];
}
@end

const NSDictionary *namesIndex;
const NSDictionary *typesIndex;

static void PrepareTypeNamesAndValues( void ) {
    
    NSMutableArray * typeNames = [NSMutableArray array];
    
    typeNames[BAValueTypeUndefined] = @"Undefined";
    typeNames[BAValueTypeBool] = @"Bool";
    typeNames[BAValueTypeInteger] = @"Integer";
    typeNames[BAValueTypeFloat] = @"Float";
    typeNames[BAValueTypeCString] = @"CString";
    typeNames[BAValueTypeCArray] = @"CArray";
    typeNames[BAValueTypeString] = @"String";
    typeNames[BAValueTypeObject] = @"Object";
    typeNames[BAValueTypeCollection] = @"Collection";
    typeNames[BAValueTypeClass] = @"Class";
    
    NSMutableDictionary *names = [NSMutableDictionary dictionary];
    NSMutableDictionary *types = [NSMutableDictionary dictionary];
    
    for (NSUInteger i=0; i<BAValueTypeCount; ++i) {
        id type = @(i);
        id name = typeNames[i];
        names[type] = name;
        types[name] = type;
    }
    
    namesIndex = names;
    typesIndex = types;
}

NSString *NSStringForBAValueType(BAValueType ivarType) {
    return namesIndex[@(ivarType)] ?: namesIndex[@(BAValueTypeUndefined)];
}

BAValueType BAValueTypeForNSString(NSString *ivarName) {
    return [typesIndex[ivarName] unsignedIntegerValue];
}

BAValueType BAIVarTypeForEncoding(const char * encoding) {
    BAValueType type = BAValueTypeUndefined;
    switch (encoding[0]) {
        case 'B':
            type = BAValueTypeBool;
            break;
        case 'c': // char
        case 'i': // int
        case 's': // short
        case 'l': // long
        case 'q': // long long
        case 'C': // unsigned char
        case 'I': // unsigned int
        case 'S': // unsigned short
        case 'L': // unsigned long
        case 'Q': // unsigned long long
            type = BAValueTypeInteger;
            break;
        case 'f': // float
        case 'd': // double
            type = BAValueTypeFloat;
            break;
        case '*': // char *
            type = BAValueTypeCString;
            break;
        case '[':
            type = BAValueTypeCArray;
            break;
        case '@':
            type = BAValueTypeForClass(NSClassFromString(BAIvarClassNameForEncoding(encoding)));
            break;
        case '#':
            return BAValueTypeClass;
            break;
        case '{': // struct or object
            
            break;
        case ':': // selector
        case '(': // union
        case 'b': // bit field
        case '^': // pointer
        case '?': // unknown or unsupported
        default:
            break;
    }
    return type;
}

BAValueType BAValueTypeForClass(Class class) {
    if ([class isSubclassOfClass:[NSArray class]] || [class isSubclassOfClass:[NSSet class]]) {
        return BAValueTypeCollection;
    }
    else if([class isSubclassOfClass:[NSString class]]) {
        return BAValueTypeString;
    }
    else {
        return BAValueTypeObject;
    }
}

NSString *BAIvarClassNameForEncoding(const char * encoding) {
    
    NSString *string = [NSString stringWithUTF8String:encoding];
    
    if (string.length > 3) {
        string = [string substringWithRange:NSMakeRange(2, string.length - 3)];
    }
    else if (encoding[0] == '@') {
        string = @"id";
    }
    else {
        string = nil;
    }
    
    return string;
}
