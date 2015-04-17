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

@interface BASampleArray (BASparseBitArraySize)
+ (BASampleArray *)sampleArrayForBase:(NSUInteger)base power:(NSUInteger)power;
@end

#pragma mark -

@implementation BASparseBitArray

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
        updateBlock(leaf, index, (void *)&setBit);
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

- (void)setBitArrayClass:(Class)bitArrayClass {
	NSAssert([bitArrayClass isSubclassOfClass:[BABitArray class]], @"bitArrayClass %@ does not inherit from BABitArray", bitArrayClass);
	_bitArrayClass = bitArrayClass;
}

- (BABitArray *)bits {
    if(!_bits && _level == 0) {
        @synchronized(self) {
            if(!_bits) {
                _bits = [[_bitArrayClass alloc] initWithLength:_leafSize size:[BASampleArray sampleArrayForBase:_base power:_power]];
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

- (id)initWithBase:(NSUInteger)base power:(NSUInteger)power level:(NSUInteger)level {
	self = [super initWithBase:base power:power level:level];
	if (self) {
		_bitArrayClass = [BABitArray class];
	}
	return self;
}
- (void)dealloc {
    self.bits = nil;
    [super dealloc];
}

#pragma mark - BASparseArray

- (id)initWithParent:(BASparseArray *)parent {
	self = [super initWithParent:parent];
	if (self) {
		_bitArrayClass = [(BASparseBitArray *)parent bitArrayClass];
	}
	return self;
}


#pragma mark - NSCoding
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        _bits = [[aDecoder decodeObjectForKey:@"bits"] retain];
		_bitArrayClass = NSClassFromString([aDecoder decodeObjectForKey:@"bitArrayClass"]);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
	if(_bits) {
        [aCoder encodeObject:_bits forKey:@"bits"];
	}
	if (_bitArrayClass) {
		[aCoder encodeObject:NSStringFromClass(_bitArrayClass) forKey:@"bitArrayClass"];
	}
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
- (void)updateRegion:(BARegion)region set:(BOOL)set;

@end


@implementation BASparseBitArray (SpatialStorage)

- (BASampleArray *)size {
    return [BASampleArray sampleArrayForBase:_treeBase power:_power];
}

#pragma mark - 2D translation conveniences

- (BOOL)bitAtX:(NSUInteger)x y:(NSUInteger)y {
    return [self bit:StorageIndexFor2DCoordinates(x, y, _base)];
}

- (void)updateBitAtX:(NSUInteger)x y:(NSUInteger)y set:(BOOL)set {
    [self updateBit:StorageIndexFor2DCoordinates(x, y, _base) set:set];
}

- (void)setBitAtX:(NSUInteger)x y:(NSUInteger)y {
    [self updateBitAtX:x y:y set:YES];
}

- (void)clearBitAtX:(NSUInteger)x y:(NSUInteger)y {
    [self updateBitAtX:x y:y set:NO];
}

- (BOOL)bitAtPoint2:(BAPoint2)point {
    return [self bit:StorageIndexFor2DCoordinates(point.x, point.y, _base)];
}

- (void)setPoint2:(BAPoint2)point {
    [self updateBitAtX:point.x y:point.y set:YES];
}

- (void)clearPoint2:(BAPoint2)point {
    [self updateBitAtX:point.x y:point.y set:NO];
}


#pragma mark - 3D translation conveniences
- (BOOL)bitAtX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z {
    return [self bit:StorageIndexFor3DCoordinates(x, y, z, _base)];
}

- (void)updateBitAtX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z set:(BOOL)set {
    [self updateBit:StorageIndexFor3DCoordinates(x, y, z, _base) set:set];
}

- (void)setBitAtX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z {
    [self updateBitAtX:x y:y z:z set:YES];
}

- (void)clearBitAtX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z {
    [self updateBitAtX:x y:y z:z set:NO];
}

- (void)recursiveUpdateRegion:(BARegion)region set:(BOOL)set {
    
    if(0 == _level) {
        [self.bits updateRegion:region set:set];
        if(_refreshBlock)
            _refreshBlock(self);
    }
    else {
        // partition the rectangle between the children, offset, recurse
        NSUInteger childBase = _treeBase/2;
        
        for (NSUInteger i=0; i<4; ++i) {
            
            BARegion subRegion = BARegionIntersection(region, BARegionMake(i&1 ? childBase : 0, i&2 ? childBase : 0, childBase, childBase));
            if (BARegionIsEmpty(subRegion)) {
                continue;
            }
            
            if(i&1)
                subRegion.origin.x -= childBase;
            if(i&2)
                subRegion.origin.y -= childBase;
            
            [(BASparseBitArray *)[self childAtIndex:i create:YES] recursiveUpdateRegion:subRegion set:set];
        }
    }
}

- (void)updateRegion:(BARegion)region set:(BOOL)set {
    
    NSUInteger maxIndex = StorageIndexFor2DCoordinates(BARegionGetMaxX(region), BARegionGetMaxY(region), _treeBase);
    if(maxIndex >= _treeSize)
        [self expandToFitSize:maxIndex+1];
    [self recursiveUpdateRegion:region set:set];
}

- (void)setRegion:(BARegion)region {
    [self updateRegion:region set:YES];
}

- (void)clearRegion:(BARegion)region {
    [self updateRegion:region set:NO];
}

- (void)recursiveWriteRegion:(BARegion)region fromArray:(id<BABitArray2D>)bitArray offset:(BAPoint2)origin dispatchGroup:(dispatch_group_t)group {
    
    if(0 == _level) {
        [self.bits writeRegion:region fromArray:bitArray offset:origin];
        if(_refreshBlock)
            _refreshBlock(self);
    }
    else {
		
        NSUInteger childBase = _treeBase/2;
        
        for (NSUInteger i=0; i<4; ++i) {
			
			BASparseBitArray *child = (BASparseBitArray *)[self childAtIndex:i create:YES];
            
			dispatch_group_enter(group);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                
                BARegion subRect = BARegionIntersection(region, BARegionMake(i&1 ? childBase : 0, i&2 ? childBase : 0, childBase, childBase));
                BAPoint2 offset = origin;
                
                if(!BARegionIsEmpty(subRect)) {
                    
                    if(i&1) {
                        subRect.origin.x -= childBase;
                        if(region.origin.x < childBase)
                            offset.x += (childBase - region.origin.x);
                    }
                    if(i&2) {
                        subRect.origin.y -= childBase;
                        if(region.origin.y < childBase)
                            offset.y += (childBase - region.origin.y);
                    }
                    
                    [child recursiveWriteRegion:subRect fromArray:bitArray offset:offset dispatchGroup:group];
                }
                dispatch_group_leave(group);
            });
        }
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

- (void)writeRegion:(BARegion)region fromArray:(id<BABitArray2D>)bitArray offset:(BAPoint2)origin {

    NSUInteger maxIndex = StorageIndexFor2DCoordinates(BARegionGetMaxX(region), BARegionGetMaxY(region), _treeBase);
    
    if(maxIndex >= _treeSize)
        [self expandToFitSize:maxIndex+1];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		dispatch_group_t group = dispatch_group_create();
        [self recursiveWriteRegion:region fromArray:bitArray offset:origin dispatchGroup:group];
		dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
		dispatch_release(group);
	});
}

- (void)writeRegion:(BARegion)region fromArray:(id<BABitArray2D>)bitArray {
    [self writeRegion:region fromArray:bitArray offset:BAPoint2Zero()];
}

- (id<BABitArray2D>)subArrayWithRegion:(BARegion)region {
    
    BABitArray *subArray = [[BABitArray alloc] initWithLength:BARegionArea(region) size:[BASampleArray sampleArrayForSize2:region.size]];
    NSUInteger width = BARegionGetWidth(region);
    NSUInteger height = BARegionGetHeight(region);
    BOOL *bits = malloc(width);
    
    for (NSUInteger y=0; y < height; ++y) {

        NSRange destRange = NSMakeRange(y * width, width);
        
        [self readBits:bits fromX:BARegionGetMinX(region) y:BARegionGetMinY(region) + y length:width];
        [subArray writeBits:bits range:destRange];
    }
    
    free(bits);
    
    return [subArray autorelease];
}

- (id)initWithBitArray:(id<BABitArray2D>)otherArray region:(BARegion)region {

    NSUInteger max = BARegionGetHeight(region) > BARegionGetWidth(region) ? BARegionGetHeight(region) : BARegionGetWidth(region);
    NSUInteger base = NextPowerOf2((uint32_t)max);

#if 0
    // be strict, no ambiguity
    NSAssert(rect.size.height == rect.size.width, @"Sparse array must have uniform size dimensions");
    NSAssert(base == rect.size.height, @"Sparse array base must be a power of 2");
#endif
    
    self = [self initWithBase:base power:2 level:0];
    if(self) {
        BAPoint2 origin = region.origin;
        region.origin = BAPoint2Zero();

        [self writeRegion:region fromArray:otherArray offset:origin];
    }
    
    return self;
}


static NSArray *BlanksForRegion(BARegion region) {
    
    NSUInteger count = region.size.width;
    char *str = malloc(sizeof(char)*count+1);
    
    str[count] = '\0';
    memset(str, '_', count);
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    for (NSUInteger i=0; i<region.size.height; ++i)
        [array addObject:[NSString stringWithCString:str encoding:NSASCIIStringEncoding]];
    
    return [[array copy] autorelease];
}

- (NSArray *)rowStringsForRegion:(BARegion)region {
    
    // Recursion through children, or iteration over the included leaves?
    // Either way, we have to do some stitching as we convert between coordinate systems
    // (the storage is indexed with a 1D coordinate system; our rect array is mapped onto it)
    
    // I vote for recursion: we re-stitch the row strings at each level
    
    // We don't need to expand -- uninitialized space is filled with blanks ('_' characters)
    if(BARegionIsEmpty(region))
        return nil;
    
    if(0 == _level) {
        if(_bits)
            return [_bits rowStringsForRegion:region];
        else
            return BlanksForRegion(region);
    }
    
    
    NSArray *childStrings[4];
    NSUInteger childBase = _treeBase/2;
    
    for (NSUInteger i=0; i<4; ++i) {
        
        BARegion childRegion = BARegionMake(i&1 ? childBase : 0, i&2 ? childBase : 0, childBase, childBase);
        BARegion subRegion = BARegionIntersection(region, childRegion);
        
        if(BARegionIsEmpty(subRegion)) {
            childStrings[i] = NULL;
            continue;
        }
        
        if(i&1)
            subRegion.origin.x -= childBase;
        if(i&2)
            subRegion.origin.y -= childBase;
        
        id child = [_children objectAtIndex:i];

        childStrings[i] = child == [NSNull null] ? BlanksForRegion(subRegion) : [child rowStringsForRegion:subRegion];
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

- (NSString *)stringForRegion:(BARegion)region {
    return [[self rowStringsForRegion:region] componentsJoinedByString:@"\n"];
}

- (NSString *)stringForRegion {
    return [[self rowStringsForRegion:BARegionMake( 0, 0, _treeBase, _treeBase)] componentsJoinedByString:@"\n"];
}

@end


#pragma mark -

@implementation BASampleArray (BASparseBitArraySize)

// This creates the sizing information for a bit array
+ (BASampleArray *)sampleArrayForBase:(NSUInteger)base power:(NSUInteger)power {
	if(power == 2)
		return [BASampleArray sampleArrayForSize2:BASize2Make(base, base)];
	
	BASampleArray *sa = [BASampleArray sampleArrayWithPower:1 order:power size:sizeof(NSUInteger)];
	for(NSUInteger i=0; i<power; ++i)
		[sa setSample:(UInt8 *)&base atIndex:i];
	
	return sa;
}

@end
