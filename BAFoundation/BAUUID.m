//
//  BAUUID.m
//  Cavebot
//
//  Created by Brent Gulanowski on 12-07-27.
//  Copyright (c) 2012 Lichen Labs. All rights reserved.
//

#import "BAUUID.h"

#import <uuid/uuid.h>


#pragma mark -
@implementation BAUUID

@synthesize bytes = _bytes;
@dynamic CFUUIDRef;
@dynamic data;

#pragma mark - Accessors
- (CFUUIDRef)newCFUUIDRef {
    return CFUUIDCreateFromUUIDBytes(NULL, _bytes);
}

- (NSData *)data {
    return [NSData dataWithBytes:&_bytes length:sizeof(CFUUIDBytes)];
}

#pragma mark - NSObject
+ (void)initialize {
    if(self == [BAUUID class]) {
        NSValueTransformer *vt = [[BAUUIDDataTransformer alloc] init];
        [NSValueTransformer setValueTransformer:vt forName:kBAUUIDValueTransformerName];
        [vt release];
    }
}

#pragma mark - NSCoding
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.data forKey:@"uuid_data"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithData:[aDecoder decodeObjectForKey:@"uuid_data"]];
}


#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone {
    
    BAUUID *copy = [[[self class] alloc] init];
    
    copy->_bytes = self->_bytes;
    
    return copy;
}


#pragma mark - BAUUID
- (id)initWithCFUUIDBytes:(CFUUIDBytes)bytes {
    self = [super init];
    if(self) {
        _bytes = bytes;
    }
    return self;
}

- (id)initWithCFUUID:(CFUUIDRef)uuidRef {
    return [self initWithCFUUIDBytes:CFUUIDGetUUIDBytes(uuidRef)];
}

- (id)initWithData:(NSData *)data {
    const CFUUIDBytes *pBytes = [data bytes];
    return [self initWithCFUUIDBytes:*pBytes];
}

- (id)initWithString:(NSString *)string {
    CFUUIDRef uuid = CFUUIDCreateFromString(NULL, (CFStringRef)string);
    BAUUID *result = [self initWithCFUUID:uuid];
    CFRelease(uuid);
    return result;
}

- (NSComparisonResult)compare:(BAUUID *)otherUuid {
    
#if 1
    int comparison = uuid_compare(&_bytes.byte0, &otherUuid->_bytes.byte0);
    
    if(comparison < 0) return NSOrderedDescending;
    if(comparison > 0) return NSOrderedAscending;
    
#else
    UInt8 *buffer = (UInt8 *)&_bytes;
    UInt8 *otherb = (UInt8 *)&otherUuid->_bytes;
    
    for (NSUInteger i=0; i<16; ++i) {
        if(buffer[i] < otherb[i])
            return NSOrderedDescending;
        else if(buffer[i] > otherb[i])
            return NSOrderedAscending;
    }
#endif
    
    return NSOrderedSame;
}

+ (BAUUID *)UUIDWithCFUUID:(CFUUIDRef)uuidRef {
    return [[[self alloc] initWithCFUUID:uuidRef] autorelease];
}

+ (BAUUID *)UUID {
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    BAUUID *result = [self UUIDWithCFUUID:uuid];
    CFRelease(uuid);
    return result;
}

+ (BAUUID *)UUIDWithData:(NSData *)data {
    return [[[self alloc] initWithData:data] autorelease];
}

@end

@implementation BAUUIDDataTransformer

NSString *kBAUUIDValueTransformerName = @"BAUUID";

- (id)transformedValue:(BAUUID *)value {
    return value.data;
}

+ (Class)transformedValueClass {
    return [NSData class];
}

- (id)reverseTransformedValue:(id)value {
    return [BAUUID UUIDWithData:value];
}

@end
