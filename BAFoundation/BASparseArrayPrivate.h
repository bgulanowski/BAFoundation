//
//  BASparseArrayPrivate.h
//  BAFoundation
//
//  Created by Brent Gulanowski on 13-03-07.
//  Copyright (c) 2013 Lichen Labs. All rights reserved.
//


#import <BAFoundation/BASparseArray.h>


static inline uint32_t StorageIndexFor2DCoordinates( uint32_t x, uint32_t y, uint32_t base ) {
    uint32_t leafIndex = LeafIndexFor2DCoordinates(x, y, base);
    return leafIndex * base * base + (y%base)*base + x%base;
}

static inline uint32_t StorageIndexFor3DCoordinates( uint32_t x, uint32_t y, uint32_t z, uint32_t base ) {
    uint32_t leafIndex = LeafIndexFor3DCoordinates(x, y, z, base);
    return leafIndex * base*base*base + (z%base)*base*base + (y%base)*base + x%base;
}

@interface BASparseArray (SparseArrayPrivate)

- (id)initWithBase:(NSUInteger)base power:(NSUInteger)power level:(NSUInteger)level;
- (id)initWithChild:(BASparseArray *)child position:(NSUInteger)position;
- (id)initWithParent:(BASparseArray *)parent;

- (NSUInteger)treeSizeForStorageIndex:(NSUInteger)index depth:(NSUInteger *)pDepth;
- (NSUInteger)treeSizeForStorageIndex:(NSUInteger)index;

- (BASparseArray *)childAtIndex:(NSUInteger)index create:(BOOL)create;

- (BASparseArray *)childForStorageIndex:(NSUInteger)storageIndex offset:(NSUInteger*)pOffset;

- (void)initializeChildren:(void (^)(BASparseArray *child))initializeBlock;

@end
