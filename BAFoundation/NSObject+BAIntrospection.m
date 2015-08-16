//
//  NSObject+BAIntrospection.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 2015-08-16.
//  Copyright (c) 2015 Marketcircle Inc. All rights reserved.
//

#import "NSObject+BAIntrospection.h"

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
    return [[self class]  publicClassName];
}

+ (NSArray *)instanceVariableTypeInfos {
    
    NSMutableArray *typeInfos = [NSMutableArray array];

    unsigned int count;
    Ivar *ivars = class_copyIvarList(self, &count);
    
    for (unsigned int index=0; index<count; ++index) {
        [typeInfos addObject:[BAIvarInfo ivarInfoWithIvar:ivars[index]]];
    }
    
    free(ivars);
    
    return typeInfos;
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
        self.type = BAIVarTypeForEncoding(encoding);
        
        // for debugging
        self.encoding = [NSString stringWithUTF8String:encoding];
    }
    return self;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"%@: %@", self.name, self.encoding];
}

+ (instancetype)ivarInfoWithIvar:(Ivar)ivar {
    return [[self alloc] initWithIvar:ivar];
}
@end

const NSDictionary *namesIndex;
const NSDictionary *typesIndex;

static void PrepareTypeNamesAndValues( void ) {
    
    NSMutableArray * typeNames = [NSMutableArray array];
    
    typeNames[BAIvarTypeBool] = @"Bool";
    typeNames[BAIvarTypeInteger] = @"Integer";
    typeNames[BAIvarTypeFloat] = @"Float";
    typeNames[BAIvarTypeCString] = @"CString";
    typeNames[BAIvarTypeCArray] = @"CArray";
    typeNames[BAIvarTypeString] = @"String";
    typeNames[BAIvarTypeObject] = @"Object";
    typeNames[BAIvarTypeCollection] = @"Collection";
    typeNames[BAIvarTypeClass] = @"Class";
    
    NSMutableDictionary *names = [NSMutableDictionary dictionary];
    NSMutableDictionary *types = [NSMutableDictionary dictionary];
    
    for (NSUInteger i=0; i<BAIvarTypeCount; ++i) {
        id type = @(i);
        id name = typeNames[i];
        names[type] = name;
        types[name] = type;
    }
    
    namesIndex = names;
    typesIndex = types;
}

NSString *NSStringForBAIvarType(BAIvarType ivarType) {
    return namesIndex[@(ivarType)];
}

BAIvarType BAIvarTypeForNSString(NSString *ivarName) {
    return [typesIndex[ivarName] unsignedIntegerValue];
}

BAIvarType BAIVarTypeForEncoding(const char * encoding) {
    BAIvarType type = BAIvarTypeUndefined;
    switch (encoding[0]) {
        case 'B':
            type = BAIvarTypeBool;
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
            type = BAIvarTypeInteger;
            break;
        case 'f': // float
        case 'd': // double
            type = BAIvarTypeFloat;
            break;
        case '*': // char *
            type = BAIvarTypeCString;
            break;
        case '[':
            type = BAIvarTypeCArray;
            break;
        case '@':
            type = BAIvarTypeForClass(BAIvarClassForEncoding(encoding));
            break;
        case '#':
            return BAIvarTypeClass;
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

BAIvarType BAIvarTypeForClass(Class class) {
    if ([class isSubclassOfClass:[NSArray class]] || [class isSubclassOfClass:[NSSet class]]) {
        return BAIvarTypeCollection;
    }
    else if([class isSubclassOfClass:[NSString class]]) {
        return BAIvarTypeString;
    }
    else {
        return BAIvarTypeObject;
    }
}

Class BAIvarClassForEncoding(const char * encoding) {
    if (encoding[0] == '{' &&strlen(encoding) > 3) {
        // ???: is this right?
        NSString *string = [NSString stringWithUTF8String:&encoding[1]];
        string = [string substringToIndex:string.length - 1];
        return NSClassFromString(string);
    }
    else {
        return BAIvarTypeUndefined;
    }
}
