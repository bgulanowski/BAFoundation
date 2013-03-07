//
//  BASparseArray.h
//  BAFoundation
//
//  Created by Brent Gulanowski on 13-03-07.
//  Copyright (c) 2013 Lichen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>


#define TABLE_SIZE 10

extern uint32_t powersOf2[TABLE_SIZE];
extern uint32_t powersOf4[TABLE_SIZE];
extern uint32_t powersOf8[TABLE_SIZE];


@class BASparseArray;


typedef void (^SparseArrayToggle)(BASparseArray *sparseArray, NSUInteger index, BOOL set);
typedef void (^SparseArrayUpdate)(BASparseArray *sparseArray, NSUInteger index, void *newValue);
typedef void  (^SparseArrayBuild)(BASparseArray *sparseArray, NSUInteger childIndex);
typedef void (^SparseArrayExpand)(BASparseArray *sparseArray, NSUInteger newLevel);


static inline NSInteger powi ( NSInteger base, NSUInteger exp ) {
    NSInteger result = base;
    if(0 == exp) return 1;
    while(--exp) result *= base;
    return result;
}

static inline uint32_t NextPowerOf2( uint32_t v ) {
    
    v--;
    v |= v >> 1;
    v |= v >> 2;
    v |= v >> 4;
    v |= v >> 8;
    v |= v >> 16;
    v++;
    
    return v;
}


extern uint32_t LeafIndexFor2DCoordinates(uint32_t x, uint32_t y, uint32_t base);
extern void LeafCoordinatesForIndex2D(uint32_t leafIndex, uint32_t *px, uint32_t *py);

extern uint32_t LeafIndexFor3DCoordinates(uint32_t x, uint32_t y, uint32_t z, uint32_t base);
extern void LeafCoordinatesForIndex3D(uint32_t leafIndex, uint32_t *px, uint32_t *py, uint32_t *pz);

extern uint32_t LeafIndexForCoordinates(uint32_t *coords, uint32_t base, uint32_t power);
extern void LeafCoordinatesForIndex(uint32_t leafIndex, uint32_t *coords, uint32_t power);

@interface BASparseArray : NSObject<NSCoding> {
    
    SparseArrayBuild _enlargeBlock;
    SparseArrayExpand _expandBlock;
    
    NSMutableArray *_children; // interior nodes
    
    __weak id _userObject;
    
    NSUInteger _base;  // size of each dimensions of each leaf node
    NSUInteger _power; // number of dimensions, usually 1 for line, 2 for plane, 3 for volume
    NSUInteger _scale; // number of children of each interior node: 2^power
    NSUInteger _level; // distance to the leaves (level zero); max level is 9 in 32-bit mode
    NSUInteger _leafSize; // maximum storable bits in a leaf node: base^power
    NSUInteger _treeSize; // maximum storable bits for the while sub-tree: treeBase^power = (base * 2^level)^power = leafSize * 2^(level+power)
    NSUInteger _treeBase; // size of each dimension of the whole sub-tree: base * 2^level
    
    BOOL _enableArchiveCompression;
}

@property (nonatomic, strong)  SparseArrayBuild buildBlock;
@property (nonatomic, strong) SparseArrayExpand expandBlock;

@property (nonatomic, readonly) NSArray *children;

@property (nonatomic, weak) id userObject;

@property (nonatomic, readonly) NSUInteger base;
@property (nonatomic, readonly) NSUInteger power;
@property (nonatomic, readonly) NSUInteger level;
@property (nonatomic, readonly) NSUInteger scale;
@property (nonatomic, readonly) NSUInteger leafSize;
@property (nonatomic, readonly) NSUInteger treeSize;
@property (nonatomic, readonly) NSUInteger treeBase;

@property (nonatomic) BOOL enableArchiveCompression;

// The initial tree always has two levels (0 and 1)
// The root, at level 1, has <scale> children, all leaves, each with <leafSize> storage
- (id)initWithBase:(NSUInteger)base power:(NSUInteger)power;

- (void)expandToFitSize:(NSUInteger)newTreeSize;

- (BASparseArray *)childAtIndex:(NSUInteger)index;
- (BASparseArray *)leafForStorageIndex:(NSUInteger)index offset:(NSUInteger *)pOffset;

@end
