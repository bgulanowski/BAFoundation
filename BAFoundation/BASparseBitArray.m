//
//  SparseBitArray.m
//  Dungineer
//
//  Created by Brent Gulanowski on 12-10-25.
//  Copyright (c) 2012 Lichen Labs. All rights reserved.
//

#import <BAFoundation/BASparseBitArray.h>

#import "BASparseArrayPrivate.h"

#import <BAFoundation/NSData+GZip.h>
#import <BAFoundation/BAFunctions.h>


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
    SparseArrayUpdate updateBlock = leaf.updateBlock;
    
    index -= offset;
    if(setBit)
        [bits setBit:index];
    else
        [bits clearBit:index];
    if(updateBlock)
        updateBlock(self, index, (void *)&setBit);
}

- (void)recursiveUpdateRange:(NSRange)range set:(BOOL)setBits {
    
    NSUInteger maxIndex = range.location + range.length;

    if(!_level) {
        NSAssert(maxIndex < _leafSize, @"node traversal error; updating range %@", NSStringFromRange(range));
        if(setBits)
            [self.bits setRange:range];
        else
            [self.bits clearRange:range];
        if(_rangeUpdateBlock)
            _rangeUpdateBlock(self, range, setBits);
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
            [child updateRange:NSMakeRange(range.location-offset, length) set:setBits];
            dispatch_group_leave(group);
        });
        range.location += length;
        range.length -= length;
    }
}

- (void)updateRange:(NSRange)range set:(BOOL)setBits {
    
    NSUInteger maxIndex = range.location + range.length;
    
    if(maxIndex >= _treeSize)
        [self expandToFitSize:maxIndex];
    
    [self recursiveUpdateRange:range set:setBits];    
}


#pragma mark - Accessors
+ (BASampleArray *)sampleArrayForBase:(NSUInteger)base power:(NSUInteger)power {
    if(power == 2)
        return [BASampleArray sampleArrayForSize2d:CGSizeMake(base, base)];
    
    BASampleArray *sa = [BASampleArray sampleArrayWithPower:1 order:power size:sizeof(NSUInteger)];
    for(NSUInteger i=0; i<power; ++i)
        [sa setSample:(UInt8 *)&base atIndex:i];
    
    return sa;
}

- (BABitArray *)bits {
    if(!_bits && _level == 0) {
        @synchronized(self) {
            if(!_bits) {
                _bits = [[BABitArray alloc] initWithLength:_leafSize size:[[self class] sampleArrayForBase:_base power:_power]];
                _bits.enableArchiveCompression = self.enableArchiveCompression;
            }
        }
    }
    return _bits;
}

- (NSUInteger)length { return _treeSize; }

- (NSUInteger)count {

    if(_level == 0) {
        NSAssert([_bits checkCount], @"count check failed");
        return [_bits count];
    }
    
    NSUInteger count = 0;
    
    for (id child in _children)
        if(child != [NSNull null])
            count += [child count];
    
    return count;
}


#pragma mark - NSObject
- (void)dealloc {
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
    if(0 == _level)
        // AVOID creating if not created
        [_bits setAll];
    else {
        for (id child in self.children) {
            if(child != [NSNull null])
                [child setAll];
        }
    }
}

- (void)clearAll {
    if(!_level)
        // AVOID creating if not created
        [_bits clearAll];
    else {
        for (id child in self.children) {
            if(child != [NSNull null])
                [child clearAll];
        }
    }
}

- (NSUInteger)firstSetBit {
    
    if(0 == _level)
        return _bits ? [_bits firstSetBit] : NSNotFound;
    
    NSUInteger firstSetBit = NSNotFound;

    for (id child in self.children) {
        if(child == [NSNull null])
            continue;
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
    
    for (id child in [self.children reverseObjectEnumerator]) {
        if(child == [NSNull null])
            continue;
        lastSetBit = [child firstSetBit];
        if(NSNotFound != lastSetBit)
            break;
    }
    
    return lastSetBit;
}

- (NSUInteger)firstClearBit {
    
    if(0 == _level)
        return [_bits lastClearBit];
    
    NSUInteger firstClearBit = NSNotFound;

    for (id child in self.children) {
        if(child == [NSNull null])
            continue;
        firstClearBit = [child firstClearBit];
        if(NSNotFound != firstClearBit)
            break;
    }
    
    return firstClearBit;
}

- (NSUInteger)lastClearBit { return NSNotFound; }

- (NSUInteger)recursiveUpdateBits:(BOOL *)bits write:(BOOL)write range:(NSRange)bitRange {

    NSUInteger first = bitRange.location%_treeBase;
    NSUInteger last = first + bitRange.length;
    
    NSAssert(last <= _treeBase, @"Range exceeds bounds");
    
    if(0 == _level) {
        if(write)
            return [self.bits readBits:bits range:bitRange];
        else
            return [self.bits writeBits:bits range:bitRange];
    }
    else {
        
        NSUInteger treeSize = [self treeSizeForStorageIndex:bitRange.location + bitRange.length];
        NSUInteger childSize = treeSize >> _power;
        NSUInteger result = 0;
        
        while (bitRange.length) {
            
            NSUInteger offset = 0;
            BASparseBitArray *child = (BASparseBitArray *)[self childForStorageIndex:bitRange.location offset:&offset];
            NSUInteger length = MIN(bitRange.length, childSize - bitRange.location);
            
            result += [child recursiveUpdateBits:bits+offset write:write range:NSMakeRange(bitRange.location-offset, length)];
            bitRange.location += length;
            bitRange.length -= length;
        }
        
        return result;
    }
}

- (NSUInteger)updateBits:(BOOL *)bits write:(BOOL)write range:(NSRange)bitRange {
    
    NSUInteger maxIndex = bitRange.location + bitRange.length;
    
    if(maxIndex >= _treeSize)
        [self expandToFitSize:maxIndex];

    return [self recursiveUpdateBits:bits write:write range:bitRange];
}

- (NSUInteger)readBits:(BOOL *)bits range:(NSRange)bitRange {
    return [self updateBits:bits write:NO range:bitRange];
}

- (NSUInteger)writeBits:(BOOL * const)bits range:(NSRange)bitRange {
    return [self updateBits:bits write:YES range:bitRange];
}

- (NSString *)stringForRange:(NSRange)range {
    
    // use the fact that BOOL is just a char
    char *bits = calloc(sizeof(char), range.length);
    
    [self readBits:(BOOL *)bits range:range];
    
    for (NSUInteger i=0; i<range.length; ++i) {
        bits[i] = bits[i] ? 'S' : '_';
    }
    
    NSString *string = [NSString stringWithCString:bits encoding:NSASCIIStringEncoding];
    
    free(bits);
    
    return string;
}


//- (void)setRegion:(BARegioni)region {
//    
//}

@end


@interface BABitArray (ExposedPrivates)
- (void)updateRect:(CGRect)rect set:(BOOL)set;
@end


@implementation BASparseBitArray (SpatialStorage)

- (BASampleArray *)size {
    return [[self class] sampleArrayForBase:_treeBase power:_power];
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

- (void)recursiveUpdateRect:(CGRect)rect set:(BOOL)set {
    
    if(0 == _level) {
        [self.bits updateRect:rect set:set];
        if(_refreshBlock)
            _refreshBlock(self);
    }
    else {
        // partition the rectangle between the children, offset, recurse
        NSUInteger childBase = _treeBase/2;
        
        for (NSUInteger i=0; i<4; ++i) {
            
            CGRect subRect = CGRectIntersection(rect, CGRectMake(i&1 ? childBase : 0, i&2 ? childBase : 0, childBase, childBase));
            
            if(CGRectIsEmpty(subRect))
                continue;
            
            if(i&1)
                subRect.origin.x -= childBase;
            if(i&2)
                subRect.origin.y -= childBase;
            
            [(BASparseBitArray *)[self childAtIndex:i create:YES] recursiveUpdateRect:subRect set:set];
        }
    }
}

- (void)updateRect:(CGRect)rect set:(BOOL)set {
    
    NSUInteger maxIndex = StorageIndexFor2DCoordinates(CGRectGetMaxX(rect), CGRectGetMaxY(rect), _treeBase);
    
    if(maxIndex >= _treeSize)
        [self expandToFitSize:maxIndex+1];
    
    [self recursiveUpdateRect:rect set:set];
}

- (void)setRect:(CGRect)rect {
    [self updateRect:rect set:YES];
}

- (void)clearRect:(CGRect)rect {
    [self updateRect:rect set:NO];
}

- (void)recursiveWriteRect:(CGRect)rect fromArray:(BABitArray *)bitArray offset:(CGPoint)origin {
    
    if(0 == _level) {
        [self.bits writeRect:rect fromArray:bitArray offset:origin];
        if(_refreshBlock)
            _refreshBlock(self);
    }
    else {
        
        dispatch_group_t group = dispatch_group_create();
        
        NSUInteger childBase = _treeBase/2;
        
        for (NSUInteger i=0; i<4; ++i) {
            
            dispatch_group_enter(group);
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                
                CGRect subRect = CGRectIntersection(rect, CGRectMake(i&1 ? childBase : 0, i&2 ? childBase : 0, childBase, childBase));
                CGPoint offset = origin;
                
                if(!CGRectIsEmpty(subRect)) {
                    
                    if(i&1) {
                        subRect.origin.x -= childBase;
                        if(rect.origin.x < childBase)
                            offset.x += (childBase - rect.origin.x);
                    }
                    if(i&2) {
                        subRect.origin.y -= childBase;
                        if(rect.origin.y < childBase)
                            offset.y += (childBase - rect.origin.y);
                    }
                    
                    [(BASparseBitArray *)[self childAtIndex:i create:YES] recursiveWriteRect:subRect fromArray:bitArray offset:offset];
                }
                dispatch_group_leave(group);
            });
        }
        
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        dispatch_release(group);
    }
}

- (NSUInteger)readBits:(BOOL *)bits fromX:(NSUInteger)x y:(NSUInteger)y length:(NSUInteger)length {
    
    NSUInteger count = 0;
    BOOL *subBits = bits;
    NSUInteger remainder = length;
    NSUInteger leafCount = powi(_scale, _level);
    
    while (remainder > 0) {
        
        // Leaf data co-ordinates
        NSUInteger lx = x%_base;
        NSUInteger ly = y%_base;
        NSUInteger ll = MIN(_base-lx, remainder);
        
        NSRange bitsRange = NSMakeRange(lx + ly*_base, ll);
        
        NSUInteger leafIndex = LeafIndexFor2DCoordinates(x, y, _base);
        BASparseBitArray *leaf = nil;
        
        NSUInteger subCount = 0;
        
        if(leafIndex < leafCount)
            leaf = (BASparseBitArray *)[self leafForIndex:leafIndex];
        if(leaf)
            subCount = [leaf.bits readBits:subBits range:bitsRange];
        else
            memset(subBits, 0, ll);

        NSAssert(subCount==countBits(subBits,ll), @"count failed");

        count += subCount;
        
        remainder -= ll;
        subBits += ll;
        x += ll;
    }
    
    NSAssert(count==countBits(bits,length), @"count failed");
    
    return count;
}

- (void)writeRect:(CGRect)rect fromArray:(BABitArray *)bitArray offset:(CGPoint)origin {

    NSUInteger maxIndex = StorageIndexFor2DCoordinates(CGRectGetMaxX(rect), CGRectGetMaxY(rect), _treeBase);
    
    if(maxIndex >= _treeSize)
        [self expandToFitSize:maxIndex+1];
    
    [self recursiveWriteRect:rect fromArray:bitArray offset:origin];
}

- (void)writeRect:(CGRect)rect fromArray:(BABitArray *)bitArray {
    [self writeRect:rect fromArray:bitArray offset:CGPointZero];
}

- (id<BABitArray2D>)subArrayWithRect:(CGRect)rect {
    
    BABitArray *subArray = [[BABitArray alloc] initWithLength:rect.size.height*rect.size.width size:[BASampleArray sampleArrayForSize2d:rect.size]];
    NSUInteger width = rect.size.width;
    
    BOOL *bits = malloc(width);
    
    for (NSUInteger y=0; y<rect.size.height; ++y) {

        NSRange destRange = NSMakeRange(y * width, width);
        
        [self readBits:bits fromX:rect.origin.x y:rect.origin.y+y length:width];
        [subArray writeBits:bits range:destRange];
    }
    
    free(bits);
    
    return [subArray autorelease];
}

- (id)initWithBitArray:(id<BABitArray2D>)otherArray rect:(CGRect)rect {

    NSUInteger base = NextPowerOf2((uint32_t)(rect.size.height > rect.size.width ? rect.size.height : rect.size.width));

#if 0
    // be strict, no ambiguity
    NSAssert(rect.size.height == rect.size.width, @"Sparse array must have uniform size dimensions");
    NSAssert(base == rect.size.height, @"Sparse array base must be a power of 2");
#endif
    
    self = [self initWithBase:base power:2 level:0];
    if(self) {
        CGPoint origin = rect.origin;
        rect.origin = CGPointZero;
        
        [self writeRect:rect fromArray:otherArray offset:origin];
    }
    
    return self;
}


static NSArray *BlanksForRect(CGRect rect) {
    
    NSUInteger count = rect.size.width;
    char *str = malloc(sizeof(char)*count+1);
    
    str[count] = '\0';
    memset(str, '_', count);
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    for (NSUInteger i=0; i<rect.size.height; ++i)
        [array addObject:[NSString stringWithCString:str encoding:NSASCIIStringEncoding]];
    
    return [[array copy] autorelease];
}

- (NSArray *)rowStringsForRect:(CGRect)rect {
    
    // Recursion through children, or iteration over the included leaves?
    // Either way, we have to do some stitching as we convert between coordinate systems
    // (the storage is indexed with a 1D coordinate system; our rect array is mapped onto it)
    
    // I vote for recursion: we re-stitch the row strings at each level
    
    // We don't need to expand -- uninitialized space is filled with blanks ('_' characters)
    if(CGRectIsEmpty(rect))
        return nil;
    
    if(0 == _level) {
        if(_bits)
            return [_bits rowStringsForRect:rect];
        else
            return BlanksForRect(rect);
    }
    
    
    NSArray *childStrings[4];
    NSUInteger childBase = _treeBase/2;
    
    for (NSUInteger i=0; i<4; ++i) {
        
        CGRect childRect = CGRectMake(i&1 ? childBase : 0, i&2 ? childBase : 0, childBase, childBase);
        CGRect subRect = CGRectIntersection(rect, childRect);
        
        if(CGRectIsEmpty(subRect)) {
            childStrings[i] = NULL;
            continue;
        }
        
        if(i&1)
            subRect.origin.x -= childBase;
        if(i&2)
            subRect.origin.y -= childBase;
        
        id child = [_children objectAtIndex:i];

        childStrings[i] = child == [NSNull null] ? BlanksForRect(subRect) : [child rowStringsForRect:subRect];
    }
    
    NSMutableArray *rowStrings = [NSMutableArray array];
    
    // Concatenate strings and arrays
    if(childStrings[2]) {
        if(childStrings[3]) {
            NSUInteger count = [childStrings[0] count];
            for (NSUInteger i=0; i<count; ++i)
                [rowStrings addObject:[[childStrings[2] objectAtIndex:i] stringByAppendingString:[childStrings[3] objectAtIndex:i]]];
        }
    }
    else if(childStrings[3]) {
        [rowStrings addObjectsFromArray:childStrings[3]];
    }
    
    if(childStrings[0]) {
        if(childStrings[1]) {
            NSUInteger count = [childStrings[0] count];
            for (NSUInteger i=0; i<count; ++i)
                [rowStrings addObject:[[childStrings[0] objectAtIndex:i] stringByAppendingString:[childStrings[1] objectAtIndex:i]]];
        }
        else {
            [rowStrings addObjectsFromArray:childStrings[0]];
        }
    }
    else if(childStrings[1]) {
        [rowStrings addObjectsFromArray:childStrings[1]];
    }
    
    return [[rowStrings copy] autorelease];
}

- (NSString *)stringForRect:(CGRect)rect {
    return [[self rowStringsForRect:rect] componentsJoinedByString:@"\n"];
}

- (NSString *)stringForRect {
    return [[self rowStringsForRect:CGRectMake(0, 0, _treeBase, _treeBase)] componentsJoinedByString:@"\n"];
}

@end
