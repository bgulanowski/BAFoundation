//
//  SparseBitArray.m
//  Dungineer
//
//  Created by Brent Gulanowski on 12-10-25.
//  Copyright (c) 2012 Lichen Labs. All rights reserved.
//

#import "BASparseBitArray.h"

#import "BASparseArrayPrivate.h"

#import "NSData+GZip.h"

#import "BABitArray.h"


#pragma mark -

@implementation BASparseBitArray

#pragma mark - Properties

@synthesize bits=_bits;


#pragma mark - Private

- (void)updateBit:(NSUInteger)index set:(BOOL)setBit {
    
    if(index >= _treeSize)
        [self expandToFitSize:index+1];
    

    NSUInteger offset = 0;
    BASparseBitArray *leaf = (BASparseBitArray *)[self leafForStorageIndex:index offset:&offset];
    BABitArray *bits = leaf.bits;
    SparseArrayToggle toggleBlock = leaf.toggleBlock;
    
    index -= offset;
    if(setBit)
        [bits setBit:index];
    else
        [bits clearBit:index];
    if(toggleBlock)
        toggleBlock(self, index, setBit);
}

- (void)updateRange:(NSRange)range set:(BOOL)setBits {
    
    NSUInteger maxIndex = range.location + range.length;
    
    if(maxIndex >= _treeSize)
        [self expandToFitSize:maxIndex];
    
    if(!_level) {
        NSAssert(maxIndex < _leafSize, @"node traversal error; updating range %@", NSStringFromRange(range));
        if(setBits)
            [self.bits setRange:range];
        else
            [self.bits clearRange:range];
        return;
    }
    
    
    NSUInteger treeSize = [self treeSizeForStorageIndex:range.location + range.length];
    NSUInteger childSize = treeSize >> _power;
    dispatch_group_t group = dispatch_group_create();
    
    while (range.length) {
        
        NSUInteger offset = 0;
        BASparseBitArray *child = (BASparseBitArray *)[self childForStorageIndex:range.location offset:&offset];
        NSUInteger length = MIN(range.length, childSize - range.location);
        
        dispatch_group_enter(group);
        dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [child updateRange:NSMakeRange(range.location+offset, length) set:setBits];
            dispatch_group_leave(group);
        });
        range.location += length;
        range.length -= length;
    }
}


#pragma mark - Accessors
- (BABitArray *)bits {
    if(!_bits && _level == 0) {
        @synchronized(self) {
            if(!_bits) {
                _bits = [[BABitArray alloc] initWithLength:_leafSize];
                _bits.enableArchiveCompression = self.enableArchiveCompression;
            }
        }
    }
    return _bits;
}

- (NSUInteger)count {
    if(_level == 0)
        return [_bits count];
    
    NSUInteger count = 0;
    for (BASparseBitArray *child in _children)
        if([child isKindOfClass:[BASparseBitArray class]])
            count += child.count;
    return count;
}


#pragma mark - NSObject
- (void)dealloc {
    self.toggleBlock = nil;
    self.bits = nil;
    [super dealloc];
}


#pragma mark - NSCoding
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        _bits = [[aDecoder decodeObjectForKey:@"bits"] retain];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    if(_bits)
        [aCoder encodeObject:_bits forKey:@"bits"];
    else if(_level > 0)
        [aCoder encodeObject:_children forKey:@"children"];
}


#pragma mark - BABitArray

- (BOOL)bit:(NSUInteger)index {
    NSUInteger offset = 0;
    BASparseBitArray *leaf = (BASparseBitArray *)[self leafForStorageIndex:index offset:&offset];
    return [leaf.bits bit:index-offset];
}

- (void)setBit:(NSUInteger)index {
    [self updateBit:index set:YES];
}

- (void)clearBit:(NSUInteger)index {
    [self updateBit:index set:NO];
}

- (void)setRange:(NSRange)range {
    [self updateRange:range set:YES];
}

- (void)clearRange:(NSRange)range {
    [self updateRange:range set:NO];
}

- (void)setAll {
    if(!_level)
        [self.bits setAll];
    else
        [self initializeChildren:^(BASparseArray *child) {
            [(BASparseBitArray *)child setAll];
        }];
}

- (void)clearAll {
    if(!_level)
        [self.bits clearAll];
    else
        [self initializeChildren:^(BASparseArray *child) {
            [(BASparseBitArray *)child clearAll];
        }];
}

- (NSUInteger)firstSetBit {
    
    if(0 == _level)
        return _bits ? [_bits firstSetBit] : NSNotFound;
    
    NSUInteger firstSetBit = NSNotFound;
    
    for (BASparseBitArray *child in self.children) {
        firstSetBit = [child firstSetBit];
        if(NSNotFound != firstSetBit)
            break;
    }
    
    return firstSetBit;
}

- (NSUInteger)lastSetBit {
    
    if(0 == _level)
        return _bits ? [_bits lastSetBit] : NSNotFound;
    
    NSUInteger lastSetBit = NSNotFound;
    
    for (BASparseBitArray *child in [self.children reverseObjectEnumerator]) {
        lastSetBit = [child firstSetBit];
        if(NSNotFound != lastSetBit)
            break;
    }
    
    return lastSetBit;
}


#pragma mark - 2D translation conveniences

- (BOOL)bitAtX:(NSUInteger)x y:(NSUInteger)y {
    return [self bit:StorageIndexFor2DCoordinates((uint32_t)x, (uint32_t)y, (uint32_t)_base)];
}

- (void)updateBitAtX:(NSUInteger)x y:(NSUInteger)y set:(BOOL)set {
    [self updateBit:StorageIndexFor2DCoordinates((uint32_t)x, (uint32_t)y, (uint32_t)_base) set:set];
}

- (void)setBitAtX:(NSUInteger)x y:(NSUInteger)y {
    [self updateBitAtX:x y:y set:YES];
}

- (void)clearBitAtX:(NSUInteger)x y:(NSUInteger)y {
    [self updateBitAtX:x y:y set:NO];
}


#pragma mark - 3D translation conveniences
- (BOOL)bitAtX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z {
    return [self bit:StorageIndexFor3DCoordinates((uint32_t)x, (uint32_t)y, (uint32_t)z, (uint32_t)_base)];
}

- (void)updateBitAtX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z set:(BOOL)set {
    [self updateBit:StorageIndexFor3DCoordinates((uint32_t)x, (uint32_t)y, (uint32_t)z, (uint32_t)_base) set:set];
}

- (void)setBitAtX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z {
    [self updateBitAtX:x y:y z:z set:YES];
}

- (void)clearBitAtX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z {
    [self updateBitAtX:x y:y z:z set:NO];
}

//- (void)setRegion:(BARegioni)region {
//    
//}

@end
