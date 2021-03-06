//
//  NSObject+BAIntrospection.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 2015-08-16.
//  Copyright (c) 2015 Bored Astronaut. All rights reserved.
//

#import "NSObject+BAIntrospection.h"

#import "BAMacros.h"

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

#pragma mark - Method Introspection

+ (void)getMethodInfo:(void(^)(Method))block {
    unsigned count = 0;
    Method *methods = class_copyMethodList(self, &count);
    for (NSUInteger i = 0; i < count; ++i) {
        block(methods[i]);
    }
}

+ (NSArray<NSString *> *)methodNames {
    NSMutableArray *names = [NSMutableArray array];
    [self getMethodInfo:^(Method method) {
        SEL methodName = method_getName(method);
        [names addObject:NSStringFromSelector(methodName)];
    }];
    return names;
}

+ (NSArray<BAMethodInfo *> *)methodInfo {
    NSMutableArray *infos = [NSMutableArray array];
    [self getMethodInfo:^(Method method) {
        BAMethodInfo *info = [BAMethodInfo methodInfoWithMethod:method];
        [infos addObject:info];
    }];
    return infos;
}

@end

#pragma mark -

@implementation BAIntrospector

+ (instancetype)introspector {
    static BAIntrospector *introspector;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        introspector = [[BAIntrospector alloc] init];
    });
    return introspector;
}

- (id)valueForUndefinedKey:(NSString *)key {
    NSLog(@"Value for undefined key %@", key);
    return self;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return YES;
}

- (void)doesNotRecognizeSelector:(SEL)aSelector {
    NSLog(@"Received %@ message", NSStringFromSelector(aSelector));
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

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %@ %@>", _name, [NSString stringForValueType:_valueType], _typeName ?: @""];
}

- (instancetype)initWithName:(NSString *)name encoding:(NSString *)encoding {
    self = [super init];
    if (self) {
        _name = name;
        if ([encoding length]) {
            _valueType = [encoding encodedValueType];
            _typeName = [encoding encodedClassName];
        }
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
    return [[[self alloc] initWithIvar:ivar] autorelease];
}

- (instancetype)initWithProperty:(objc_property_t)property {
    NSString *name = [NSString stringWithCString:property_getName(property) encoding:NSASCIIStringEncoding];
    NSString *attr = [NSString stringWithCString:property_getAttributes(property) encoding:NSASCIIStringEncoding];
    NSString *code = [attr encodedAttributePropertyType];
    return [self initWithName:name encoding:code];
}

+ (instancetype)valueInfoWithProperty:(objc_property_t)property {
    return [[[self alloc] initWithProperty:property] autorelease];
}

- (NSString *)debugDescription {
    NSString *typeName = self.typeName ?: [NSString stringForValueType:self.valueType];
    return [NSString stringWithFormat:@"%@: %@ (%@)", self.name, typeName, self.encoding];
}

@end

#pragma mark -

NSArray<BAValueInfo *> *BAMethodArgumentInfo(Method method) {
    unsigned argCount = method_getNumberOfArguments(method);
    static const int buffer_len = 256;
    static char type[buffer_len];
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:argCount];
    for (unsigned i = 0; i < argCount; ++i) {
        method_getArgumentType(method, i, type, buffer_len);
        NSString *encoding = [NSString stringWithCString:type encoding:NSASCIIStringEncoding];
        [result addObject:[[BAValueInfo alloc] initWithName:nil encoding:encoding]];
    }
    
    return result;
}

@interface BAMethodInfo ()

@property (readwrite, retain) NSString *name;
@property (readwrite) BAValueType returnType;
@property (readwrite, retain) NSArray<BAValueInfo *> *arguments;

@end

@implementation BAMethodInfo

- (void)dealloc {
    [_name release];
    [_arguments release];
    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@", _name, [_arguments valueForKey:NSStringFromSelector(_cmd)]];
}

- (instancetype)initWithMethod:(Method)method {
    self = [self init];
    if (self) {
        SEL methodName = method_getName(method);
        _name = [NSStringFromSelector(methodName) retain];
        _arguments = [BAMethodArgumentInfo(method) retain];
    }
    return self;
}

+ (instancetype)methodInfoWithMethod:(Method)method {
    return [[[self alloc] initWithMethod:method] autorelease];
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
        {
            Class cls = NSClassFromString([self encodedClassName]);
            type = cls ? [cls valueType] : BAValueTypeObject;
        }
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
