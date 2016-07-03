//
//  NSObject+BAIntrospection.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 2015-08-16.
//  Copyright (c) 2015 Bored Astronaut. All rights reserved.
//

#import "NSObject+BAIntrospection.h"

// keyed by class name
static NSMutableDictionary *ivarInfoIndex;
static NSMutableDictionary *propertyInfoIndex;

const NSDictionary *namesIndex;
const NSDictionary *typesIndex;

static void PrepareTypeNamesAndValues( void );

#pragma mark -

@interface NSObject (BACompatibility)
- (NSString *)className;
@end

@interface NSString (BATypeDecoding)
- (BAValueType)encodedValueType;
- (NSString *)encodedAttributePropertyType;
- (NSString *)encodedClassName;
@end

#pragma mark -

@implementation NSObject (BAIntrospection)

+ (NSArray *)ancestors {
    NSMutableArray *ancestors = [NSMutableArray array];
    Class class = self;
    while (class != Nil) {
        [ancestors addObject:class];
        class = [class superclass];
    }
    return ancestors;
}

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
        ivarInfoIndex = [NSMutableDictionary dictionary];
    });
    return ivarInfoIndex[[self publicClassName]];
}

+ (NSArray *)createInstanceVariableInfo {
    
    NSMutableArray *typeInfos = [NSMutableArray array];
    
    unsigned int count;
    Ivar *ivars = class_copyIvarList(self, &count);
    
    for (unsigned int index=0; index<count; ++index) {
        [typeInfos addObject:[BAValueInfo valueInfoWithIvar:ivars[index]]];
    }
    
    free(ivars);
    
    return typeInfos;
}

+ (NSArray *)instanceVariableInfo {
    
    NSArray *info = [self cachedInstanceVariableInfo];
    
    if (nil == info) {
        ivarInfoIndex[[self publicClassName]] = info = [self createInstanceVariableInfo];
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
    return [[self propertyInfo] valueForKey:NSStringFromSelector(@selector(name))];
}

+ (NSArray *)cachedPropertyInfo {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        propertyInfoIndex = [NSMutableDictionary dictionary];
    });
    return propertyInfoIndex[[self publicClassName]];
}

+ (NSArray *)cachePropertyInfo:(NSArray *)info {
    propertyInfoIndex[[self publicClassName]] = info;
    return info;
}

+ (NSArray *)createPropertyInfo {
    NSMutableArray *info = [NSMutableArray array];
    [self iteratePropertiesWithBlock:^(objc_property_t property) {
        [info addObject:[BAValueInfo valueInfoWithProperty:property]];
    }];
    return info;
}

+ (NSArray *)propertyInfo {
    return propertyInfoIndex[[self publicClassName]] ?: [self cachePropertyInfo:[self createPropertyInfo]];
}

+ (BAValueInfo *)propertyInfoForName:(NSString *)name {
    for (BAValueInfo *info in [self propertyInfo]) {
        if ([info.name isEqualToString:name]) {
            return info;
        }
    }
    return nil;
}

- (BAValueInfo *)propertyInfoForName:(NSString *)name {
    return [[self class] propertyInfoForName:name];
}

+ (NSDictionary *)propertyInfoByName {
    NSArray *infos = [self propertyInfo];
    return [NSDictionary dictionaryWithObjects:infos forKeys:[infos valueForKey:NSStringFromSelector(@selector(name))]];
}

- (NSDictionary *)propertyInfoByName {
    return [[self class] propertyInfoByName];
}

+ (NSArray *)propertyInfoUpToAncestor:(Class)ancestor {
    NSMutableArray *infos = [NSMutableArray array];
    Class class = self;
    while (class != ancestor) {
        [infos addObjectsFromArray:[class propertyInfo]];
        class = [class superclass];
    }
    return infos;
}

- (NSArray *)propertyInfoUpToAncestor:(Class)ancestor {
    return [[self class] propertyInfoUpToAncestor:ancestor];
}

+ (void)logPropertyInfo {
    NSLog(@"%@", [[self propertyInfo] debugDescription]);
}

@end

#pragma mark -

@implementation BAValueInfo

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        PrepareTypeNamesAndValues();
    });
}

- (instancetype)initWithName:(NSString *)name encoding:(NSString *)encoding {
    self = [super init];
    if (self) {
        _name = name;
        _valueType = [encoding encodedValueType];
        _typeName = [encoding encodedClassName];
        // for debugging
        _encoding = encoding;
    }
    return self;
}

- (instancetype)initWithIvar:(Ivar)ivar {
    NSString *name = [NSString stringWithCString:ivar_getName(ivar) encoding:NSASCIIStringEncoding];
    NSString *code = [NSString stringWithCString:ivar_getTypeEncoding(ivar) encoding:NSASCIIStringEncoding];
    return [self initWithName:name encoding:code];
}

+ (instancetype)valueInfoWithIvar:(Ivar)ivar {
    return [[self alloc] initWithIvar:ivar];
}

- (instancetype)initWithProperty:(objc_property_t)property {
    NSString *name = [NSString stringWithCString:property_getName(property) encoding:NSASCIIStringEncoding];
    NSString *attr = [NSString stringWithCString:property_getAttributes(property) encoding:NSASCIIStringEncoding];
    NSString *code = [attr encodedAttributePropertyType];
    return [self initWithName:name encoding:code];
}

+ (instancetype)valueInfoWithProperty:(objc_property_t)property {
    return [[self alloc] initWithProperty:property];
}

- (NSString *)debugDescription {
    NSString *typeName = self.typeName ?: [NSString stringForValueType:self.valueType];
    return [NSString stringWithFormat:@"%@: %@ (%@)", self.name, typeName, self.encoding];
}

@end

#pragma mark -

@implementation NSObject (BAValueTypes)

+ (BAValueType)valueType {
    return BAValueTypeObject;
}

@end

@implementation NSArray (BAValueTypes)

+ (BAValueType)valueType {
    return BAValueTypeCollection;
}

@end

@implementation NSSet (BAValueTypes)

+ (BAValueType)valueType {
    return BAValueTypeCollection;
}

@end

@implementation NSOrderedSet (BAValueTypes)

+ (BAValueType)valueType {
    return BAValueTypeCollection;
}

@end

@implementation NSString (BAValueTypes)

+ (BAValueType)valueType {
    return BAValueTypeString;
}

+ (NSString *)stringForValueType:(BAValueType)valueType {
    return namesIndex[@(valueType)] ?: @"Undefined";
}

- (BAValueType)valueType {
    return [typesIndex[self] unsignedIntegerValue];
}

@end

#pragma mark -

@implementation NSString (BATypeDecoding)

- (BAValueType)encodedValueType {
    
    BAValueType type = BAValueTypeUndefined;
    switch ([self characterAtIndex:0]) {
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
            type = [NSClassFromString([self encodedClassName]) valueType];
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

- (NSString *)encodedAttributePropertyType {
    
    NSRange range = [self rangeOfString:@","];
    if (range.location == NSNotFound) {
        return [self substringFromIndex:1];
    }
    else {
        return [self substringWithRange:NSMakeRange(1, range.location-1)];
    }
}

- (NSString *)encodedClassName {
    
    NSString *encoding = nil;
    
    switch ([self characterAtIndex:0]) {
        case '@':
            encoding = self.length > 3 ? [self substringWithRange:NSMakeRange(2, self.length - 3)] : @"id";
            break;
            
        case '{':
            encoding = [self substringWithRange:NSMakeRange(1, self.length - 3)];
            break;
            
        default:
            break;
    }
    
    return encoding;
}

@end

#pragma mark - Functions

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

BAValueType BAValueTypeForEncoding(NSString *encoding) {
    BAValueType type = BAValueTypeUndefined;
    switch ([encoding characterAtIndex:0]) {
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
            type = BAValueTypeForClass(NSClassFromString(BAValueTypeNameForEncoding(encoding)));
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

NSString *BAValueTypeNameForEncoding(NSString *encoding) {
    
    if (encoding.length > 3) {
        encoding = [encoding substringWithRange:NSMakeRange(2, encoding.length - 3)];
    }
    else if ([encoding characterAtIndex:0] == '@') {
        encoding = @"id";
    }
    else {
        encoding = nil;
    }
    
    return encoding;
}

NSString *BAValueEncodingForPropertyAttributes(NSString *attributes) {
    NSRange range = [attributes rangeOfString:@","];
    if (range.location == NSNotFound) {
        return [attributes substringFromIndex:1];
    }
    else {
        return [attributes substringWithRange:NSMakeRange(1, range.location-1)];
    }
}
