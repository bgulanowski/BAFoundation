//
//  BASparseArray.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 13-03-07.
//  Copyright (c) 2013 Lichen Labs. All rights reserved.
//

#import "BASparseArray.h"

#import "BASparseArrayPrivate.h"


uint32_t powersOf2[TABLE_SIZE];
uint32_t powersOf4[TABLE_SIZE];
uint32_t powersOf8[TABLE_SIZE];


#pragma mark - Private Functions

// Don't call recursive functions directly from class code
static uint32_t LeafIndex2DRecursive(uint32_t x, uint32_t y, uint32_t l) {
    
    l /= 2;
    
    uint32_t result = 0;
    uint32_t childIndex = 0;
    
    if(x >= l) {
        x -= l; // or x%=l
        ++childIndex;
    }
    if(y >= l) {
        y -= l; // or y%=l
        childIndex+=2;
    }
    
    if(l > 1)
        result = l*l*childIndex + LeafIndex2DRecursive(x, y, l);
    else
        result = childIndex;
    
    return result;
}

static uint32_t LeafIndex3DRecursive(uint32_t x, uint32_t y, uint32_t z, uint32_t l) {
    
    l /= 2;
    
    uint32_t result = 0;
    uint32_t childIndex = 0;
    
    if(x >= l) {
        x -= l; // or x%=l
        ++childIndex;
    }
    if(y >= l) {
        y -= l; // or y%=l
        childIndex+=2;
    }
    if(z >= l) {
        z -= l; // or z%=l
        childIndex+=4;
    }
    
    if(l > 1)
        result = l*l*l*childIndex + LeafIndex3DRecursive(x, y, z, l);
    else
        result = childIndex;
    
    return result;
}

static uint32_t LeafIndexRecursive(uint32_t *coords, uint32_t count) {
    
    uint32_t result = 0;
    
    // TODO: complete
    
    return result;
}


#pragma mark - Functions
// This expects sample coordinates for x,y
uint32_t LeafIndexFor2DCoordinates(uint32_t x, uint32_t y, uint32_t base) {
    
    // convert sample coordinates to leaf coordinates
    x /= base;
    y /= base;
    
    uint32_t max = MAX(x,y);
    
    // provide a power of 2 that will fit the current value, so increment max so 1->2, 2->4, 4->8, etc
    return (max == 0) ? 0 : LeafIndex2DRecursive(x, y, NextPowerOf2(max+1));
}

// This is the reverse operation of LeafIndexFor2DCoordinates();
// it's not used, so it's mostly to confirm I understand what's going on - at least theoretically
void LeafCoordinatesForIndex2D(uint32_t leafIndex, uint32_t *px, uint32_t *py) {
    
    if(leafIndex < 1) return;
    
    uint32_t x = 0;
    uint32_t y = 0;
    uint32_t i = 1;
    
    while (powersOf4[i] <= leafIndex && i < TABLE_SIZE) ++i;
    
    assert(powersOf4[i] > leafIndex);
    
    while (i-- > 0) {
        
        uint32_t c = powersOf4[i];
        uint32_t offset = leafIndex / c;
        
        if(offset & 0x02)
            y += powersOf2[i];
        if(offset & 0x01)
            x += powersOf2[i];
        
        leafIndex %= c;
    }
    
    *px = x;
    *py = y;
}

uint32_t LeafIndexFor3DCoordinates(uint32_t x, uint32_t y, uint32_t z, uint32_t base) {
    
    // convert sample coordinates to leaf coordinates
    x /= base;
    y /= base;
    z /= base;
    
    uint32_t max = MAX(MAX(x,y), z);
    
    // provide a power of 2 that will fit the current value, so increment max so 1->2, 2->4, 4->8, etc
    return (max == 0) ? 0 : LeafIndex3DRecursive(x, y, z, NextPowerOf2(max+1));
}

static inline uint32_t LeafCoordinatesFromAbsolute3D(uint32_t base, uint32_t *x, uint32_t *y, uint32_t *z) {
    uint32_t index = LeafIndexFor3DCoordinates(*x, *y, *z, base);
    *x = *x%base;
    *y = *y%base;
    *z = *z%base;
    return index;
}

// As with the 2D equivalent, this is not used, just important to understand
void LeafCoordinatesForIndex3D(uint32_t leafIndex, uint32_t *px, uint32_t *py, uint32_t *pz) {
    
    if(leafIndex < 1) return;
    
    uint32_t x = 0, y = 0, z = 0;
    uint32_t i = 1;
    
    while (powersOf4[i] <= leafIndex) ++i;
    
    while (i-- > 0) {
        
        uint32_t c = powersOf8[i];
        uint32_t offset = leafIndex / c;
        
        if(offset & 0x04)
            z += powersOf2[i];
        if(offset & 0x02)
            y += powersOf2[i];
        if(offset & 0x01)
            x += powersOf2[i];
        
        leafIndex %= c;
    }
    
    *px = x;
    *py = y;
    *pz = z;
}

uint32_t LeafIndexForCoordinates(uint32_t *coords, uint32_t base, uint32_t power) {
    
    uint32_t result = 0;
    
    // TODO:
    
    return result;
}

void LeafCoordinatesForIndex(uint32_t leafIndex, uint32_t *coords, uint32_t power) {
    // TODO:
}


@implementation BASparseArray

#pragma mark - Properties

@synthesize buildBlock=_enlargeBlock;
@synthesize expandBlock=_expandBlock;

@synthesize children=_children;

@synthesize userObject=_userObject;

@synthesize base=_base;
@synthesize power=_power;
@synthesize level=_level;
@synthesize scale=_scale;
@synthesize leafSize=_leafSize;
@synthesize treeSize=_treeSize;
@synthesize treeBase=_treeBase;
@synthesize enableArchiveCompression=_enableArchiveCompression;


#pragma mark - Private

- (id)initWithBase:(NSUInteger)base power:(NSUInteger)power level:(NSUInteger)level {
    
    self = [super init];
    
    if(self) {
        
        // fundamental attributes
        _base = base;
        _power = power;
        _level = level;
        
        // cached derived attributes
        _scale = powi(2, _power);
        _leafSize = powi(_base, _power);
        _treeBase = _base * powi(2, _level);
        _treeSize = _leafSize << (_level * _power);
        
        if(_level > 0) {
            _children = [[NSMutableArray alloc] init];
            for (NSUInteger i=0; i<_scale; ++i)
                [_children addObject:[NSNull null]];
        }
    }
    
    return self;
}

- (id)initWithChild:(BASparseArray *)child position:(NSUInteger)position {
    
    self = [self initWithBase:child.base power:child.power level:child.level + 1];
    
    if(self) {
        [_children replaceObjectAtIndex:position withObject:child];
    }
    return self;
}

- (id)initWithParent:(BASparseArray *)parent {
    return [self initWithBase:parent.base power:parent.power level:parent.level-1];
}

- (NSUInteger)treeSizeForStorageIndex:(NSUInteger)index depth:(NSUInteger *)pDepth {
    
    if(index < _leafSize)
        return _leafSize;
    
    
    NSUInteger depth = 0;
    NSUInteger size = _leafSize;
    
    do {
        size = size << _power;
        depth ++;
        
    } while(size < index);
    
    if(pDepth)
        *pDepth = depth;
    
    return size;
}

- (NSUInteger)treeSizeForStorageIndex:(NSUInteger)index {
    return [self treeSizeForStorageIndex:index depth:NULL];
}

- (BASparseArray *)childAtIndex:(NSUInteger)index create:(BOOL)create {
    
    NSAssert(index < _scale, @"child index calculation error; no child with index %u", (unsigned)index);
    NSAssert(_children, @"No children!");
    
    id child = [_children objectAtIndex:index];
    
    if(child == [NSNull null]) {
        if(create) {
            child = [[[self class] alloc] initWithParent:self];
            [_children replaceObjectAtIndex:index withObject:child];
            [child release];
            if(_enlargeBlock)
                _enlargeBlock(self, index);
        }
        else
            child = nil;
    }
    
    return child;
}

- (BASparseArray *)childForStorageIndex:(NSUInteger)storageIndex offset:(NSUInteger*)pOffset {
    
    if(!_level) {
        NSAssert(storageIndex < _leafSize, @"node traversal error; locating child for bit %u", (unsigned)storageIndex);
        if(pOffset)
            *pOffset = 0;
        return self;
    }
    
    
    NSUInteger size = _treeSize >> _power;
    NSUInteger childIndex = storageIndex / size;
    BASparseArray *child = [self childAtIndex:childIndex create:YES];
    
    if(pOffset)
        *pOffset = size*childIndex;
    
    return child;
}

- (void)initializeChildren:(void (^)(BASparseArray *child))initializeBlock {
    
    dispatch_group_t group = dispatch_group_create();
    NSUInteger count = [_children count];
    
    for(NSUInteger i=0; i<count; ++i) {
        
        BASparseArray *child = [self childAtIndex:i];
        
        dispatch_group_enter(group);
        dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            if(setBits) [child setAll]; else [child clearAll];
            if(initializeBlock)
                initializeBlock(child);
            dispatch_group_leave(group);
        });
    }
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
}


#pragma mark - NSObject

- (void)dealloc {
    self.buildBlock = nil;
    self.expandBlock = nil;
    [_children release], _children = nil;
    [super dealloc];
}

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        uint32_t power = 1, square;
        for (uint32_t i=0; i<TABLE_SIZE; ++i) {
            square = power * power;
            powersOf2[i] = power;
            powersOf4[i] = square;
            powersOf8[i] = power*square;
            power <<= 1;
        }
    });
}



#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if(self) {
        _base = [aDecoder decodeIntegerForKey:@"base"];
        _power = [aDecoder decodeIntegerForKey:@"power"];
        _level = [aDecoder decodeIntegerForKey:@"level"];
        _scale = [aDecoder decodeIntegerForKey:@"scale"];
        _leafSize = [aDecoder decodeIntegerForKey:@"leafSize"];
        _treeSize = [aDecoder decodeIntegerForKey:@"treeSize"];
        _treeBase = [aDecoder decodeIntegerForKey:@"treeBase"];
        _children = [[aDecoder decodeObjectForKey:@"children"] retain];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:_base forKey:@"base"];
    [aCoder encodeInteger:_power forKey:@"power"];
    [aCoder encodeInteger:_level forKey:@"level"];
    [aCoder encodeInteger:_scale forKey:@"scale"];
    [aCoder encodeInteger:_leafSize forKey:@"leafSize"];
    [aCoder encodeInteger:_treeSize forKey:@"treeSize"];
    [aCoder encodeInteger:_treeBase forKey:@"treeBase"];
}


#pragma mark - BASparseArray

- (id)initWithBase:(NSUInteger)base power:(NSUInteger)power {
    return [self initWithBase:base power:power level:1];
}

- (void)expandToFitSize:(NSUInteger)newTreeSize {
    
    NSUInteger oldLevel = _level;
    
    while(newTreeSize > _treeSize) {
        ++_level;
        _treeBase = _treeBase << 1;
        _treeSize = _treeSize << _power;
        
        BASparseArray *newChild = [[[self class] alloc] initWithParent:self];
        
        newChild->_children = _children;
        _children = [[NSMutableArray alloc] init];
        [_children addObject:newChild];
        [newChild release];
        
        for (NSUInteger i=1; i<_scale; ++i)
            [_children addObject:[NSNull null]];
    }
    
    if(_level > oldLevel && _expandBlock)
        _expandBlock(self, _level);
}

- (BASparseArray *)childAtIndex:(NSUInteger)index {
    return [self childAtIndex:index create:NO];
}

- (BASparseArray *)leafForStorageIndex:(NSUInteger)index offset:(NSUInteger *)pOffset {
    
    NSUInteger offset = 0;
    BASparseArray *child = [self childForStorageIndex:index offset:&offset];
    
    NSAssert(index >= offset, @"offset calculation error.");
    
    if(child == self)
        return self;
    
    if(pOffset)
        *pOffset += offset;
    
    return [child leafForStorageIndex:index-offset offset:pOffset];
}

@end
