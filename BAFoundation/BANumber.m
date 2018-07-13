//
//  BANumber.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 2018-07-13.
//  Copyright © 2018 Lichen Labs. All rights reserved.
//

#import "BANumber.h"

@implementation BANumber {
    NSUInteger *_places;
    BOOL _negative;
    BOOL _overflow;
}

- (instancetype)init {
    return [self initWithBase:16 size:16 initialValue:0];
}

- (void)dealloc {
    [super dealloc];
    free(_places);
}

- (NSUInteger)value {
    return 0;
}

- (instancetype)initWithBase:(NSUInteger)base size:(NSUInteger)size initialValue:(NSUInteger)value {
    self = [super init];
    if (self) {
        _base = base;
        _size = size;
        _places = malloc(sizeof(NSUInteger) * _size);
    }
    return self;
}

- (instancetype)initWithBase:(NSUInteger)base {
    return [self initWithBase:base size:16 initialValue:0];
}

- (void)increment {
    if (_overflow) {
        return;
    }
    NSUInteger d = 0;
    do {
        _places[d] = (_places[d] + 1)%_base;
        d++;
    } while (d < _size && _places[d] == 0);
    _overflow = d == _size;
}

- (NSUInteger)digitAtPlace:(NSUInteger)place {
    NSAssert(place < _base, @"asked to return digit beyond bounds");
    return _places[place];
}

@end
