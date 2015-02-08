//
//  BASparseArray.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 13-03-07.
//  Copyright (c) 2013 Lichen Labs. All rights reserved.
//

#import <BAFoundation/BASparseArray.h>

#import "BASparseArrayPrivate.h"
#import <BAFoundation/BAFunctions.h>


NSUInteger powersOf2[TABLE_SIZE];
NSUInteger powersOf4[TABLE_SIZE];
NSUInteger powersOf8[TABLE_SIZE];


#pragma mark - Private Functions

/* The leaf index calculations first determine the maximum size of the hypercube containing the desired coordinates.
 * Then they divide that space into 2^power partitions, and determine in which of those partitions the point lies.
 *
 * Find the offset of the next child partition: the index of the child, from 0 to 2^power-1, multiplied by l^power,
 * the size of each child partition. Offset the coordinates to be relative to the child partition's first element,
 * then recursive call using the new coordinates and child size (half that of the parent).
 *
 * The index is a recursive sum which terminates when we cannot divide the children any more.
 */

// Don't call recursive functions directly from class code
static NSUInteger LeafIndex2DRecursive(NSUInteger x, NSUInteger y, NSUInteger l) {
    
    l /= 2;
    
    NSUInteger result = 0;
    NSUInteger childIndex = 0;
    
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

static NSUInteger LeafIndex3DRecursive(NSUInteger x, NSUInteger y, NSUInteger z, NSUInteger l) {
    
    l /= 2;
    
    NSUInteger result = 0;
    NSUInteger childIndex = 0;
    
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

static NSUInteger LeafIndexRecursive(NSUInteger *coords, NSUInteger count, NSUInteger l) {
    
    l /= 2;
    
    NSUInteger result = 0;
    NSUInteger childIndex = 0;
    NSUInteger offset = 1;

    for (NSUInteger i=0; i<count; ++i) {
        if(coords[i] >= l) {
            coords[i] -= l;
            childIndex += offset;
        }
        offset += 2;
    }
    
    if(l > 1)
        result = (NSUInteger)powi(l, count)*childIndex + LeafIndexRecursive(coords, count, l);
    else
        result = childIndex;
    
    return result;
}


#pragma mark - Functions
// This expects sample coordinates for x,y
NSUInteger LeafIndexFor2DCoordinates(NSUInteger x, NSUInteger y, NSUInteger base) {
    
    // convert sample coordinates to leaf coordinates
    x /= base;
    y /= base;
    
    NSUInteger max = MAX(x,y);
    
    // provide a power of 2 that will fit the current value, so increment max so 1->2, 2->4, 4->8, etc
    return (max == 0) ? 0 : LeafIndex2DRecursive(x, y, NextPowerOf2((uint32_t)max+1));
}

// This is the reverse operation of LeafIndexFor2DCoordinates();
// it's not used, so it's mostly to confirm I understand what's going on - at least theoretically
void LeafCoordinatesForIndex2D(NSUInteger leafIndex, NSUInteger *px, NSUInteger *py) {
    
    if(leafIndex < 1) return;
    
    NSUInteger x = 0;
    NSUInteger y = 0;
    NSUInteger i = 1;
    
    while (powersOf4[i] <= leafIndex && i < TABLE_SIZE) ++i;
    
    assert(powersOf4[i] > leafIndex);
    
    while (i-- > 0) {
        
        NSUInteger c = powersOf4[i];
        NSUInteger offset = leafIndex / c;
        
        if(offset & 0x02)
            y += powersOf2[i];
        if(offset & 0x01)
            x += powersOf2[i];
        
        leafIndex %= c;
    }
    
    *px = x;
    *py = y;
}

NSUInteger LeafIndexFor3DCoordinates(NSUInteger x, NSUInteger y, NSUInteger z, NSUInteger base) {
    
    // convert sample coordinates to leaf coordinates
    x /= base;
    y /= base;
    z /= base;
    
    NSUInteger max = MAX(MAX(x,y), z);
    
    // provide a power of 2 that will fit the current value, so increment max so 1->2, 2->4, 4->8, etc
    return (max == 0) ? 0 : LeafIndex3DRecursive(x, y, z, NextPowerOf2((uint32_t)max+1));
}

// As with the 2D equivalent, this is not used, just important to understand
void LeafCoordinatesForIndex3D(NSUInteger leafIndex, NSUInteger *px, NSUInteger *py, NSUInteger *pz) {
    
    if(leafIndex < 1) return;
    
    NSUInteger x = 0, y = 0, z = 0;
    NSUInteger i = 1;
    
    while (powersOf4[i] <= leafIndex) ++i;
    
    while (i-- > 0) {
        
        NSUInteger c = powersOf8[i];
        NSUInteger offset = leafIndex / c;
        
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

NSUInteger LeafIndexForCoordinates(NSUInteger *coords, NSUInteger base, NSUInteger power) {
    
    if(power == 2)
        return LeafIndexFor2DCoordinates(coords[0], coords[1], base);
    
    if(power == 3)
        return LeafIndexFor3DCoordinates(coords[0], coords[1], coords[2], base);
    
    NSUInteger max = 0;
    
    for(NSUInteger i=0; i<power; ++i) {
        max = MAX(max, coords[i]);
        coords[i]/=base;
    }
    
    return max == 0 ? 0 : LeafIndexRecursive(coords, power, NextPowerOf2((uint32_t)max+1));
}

void LeafCoordinatesForIndex(NSUInteger leafIndex, NSUInteger *coords, NSUInteger power) {
    // TODO:
}


@implementation BASparseArray

#pragma mark - Properties

@synthesize buildBlock=_enlargeBlock;
@synthesize expandBlock=_expandBlock;
@synthesize updateBlock=_updateBlock;
@synthesize refreshBlock=_refreshBlock;

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
    
	id child;
	
	@synchronized(_children) {
		child = [_children objectAtIndex:index];
	
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
    self.updateBlock = nil;
    self.refreshBlock = nil;
    self.userObject = nil;
    [_children release], _children = nil;
    [super dealloc];
}

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSUInteger power = 1, square;
        for (NSUInteger i=0; i<TABLE_SIZE; ++i) {
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
	[aCoder encodeObject:_children forKey:@"children"];
}


#pragma mark - BASparseArray

- (void)recursiveWalkChildren:(SparseArrayWalk)walkBlock indexPath:(NSIndexPath *)indexPath offset:(NSUInteger *)offset {
    
    if(walkBlock(self, indexPath, offset) || 0 == _level)
        return;

    NSUInteger *childOffset = calloc(sizeof(NSUInteger), _power);
    NSUInteger i=0;
    
    for (id child in self.children) {
        if(child != [NSNull null]) {
            for (NSUInteger j=0; i<_power; ++i)
                childOffset[j] = offset[j] + _treeBase*(i&(1<<j));
            [child recursiveWalkChildren:walkBlock indexPath:[indexPath indexPathByAddingIndex:i] offset:childOffset];
        }
        ++i;
    }
    
    free(childOffset);
}

- (void)walkChildren:(SparseArrayWalk)walkBlock {
    NSUInteger *offset = calloc(sizeof(NSUInteger), _power);
    [self recursiveWalkChildren:walkBlock indexPath:[[NSIndexPath alloc] init] offset:offset];
}

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

- (BASparseArray *)leafForIndex:(NSUInteger)index {
    
    if(_level == 1)
        return [self childAtIndex:index];
    
//    NSUInteger leafCount = _treeSize/_leafSize;
    NSUInteger childLeafCount = powi(_scale, _level-1); // leafCount/_scale;
    NSUInteger childIndex = index/childLeafCount;
    BASparseArray *child = [self childAtIndex:childIndex];
    
    return [child leafForIndex:index%childLeafCount];
}

- (BASparseArray *)leafForStorageIndex:(NSUInteger)index offset:(NSUInteger *)pOffset {
    
    NSUInteger offset = 0;
    BASparseArray *child = [self childForStorageIndex:index offset:&offset];
    
    NSAssert(index >= offset, @"offset calculation error.");
    
//    if(child->_level == 0)
//        return child;
    if(child == self)
        return self;
    
    if(pOffset)
        *pOffset += offset;
    else
        pOffset = &offset;
    
    return [child leafForStorageIndex:index-offset offset:pOffset];
}

@end
