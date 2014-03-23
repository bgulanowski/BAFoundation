//
//  BASparseArrayPrivate.h
//  BAFoundation
//
//  Created by Brent Gulanowski on 13-03-07.
//  Copyright (c) 2013 Lichen Labs. All rights reserved.
//


#import <BAFoundation/BASparseArray.h>


static inline NSUInteger StorageIndexFor2DCoordinates( NSUInteger x, NSUInteger y, NSUInteger base ) {
    NSUInteger leafIndex = LeafIndexFor2DCoordinates(x, y, base);
    return leafIndex * base * base + (y%base)*base + x%base;
}

static inline NSUInteger StorageIndexFor3DCoordinates( NSUInteger x, NSUInteger y, NSUInteger z, NSUInteger base ) {
    NSUInteger leafIndex = LeafIndexFor3DCoordinates(x, y, z, base);
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
