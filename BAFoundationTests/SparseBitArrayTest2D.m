//
//  SparseBitArrayTest2D.m
//  Dungineer
//
//  Created by Brent Gulanowski on 12-10-26.
//  Copyright (c) 2012 Lichen Labs. All rights reserved.
//

#import "SparseBitArrayTest2D.h"

#import "BASparseBitArray.h"
#import "BAFunctions.h"


#define      BASE 16ul
#define     POWER 2ul
#define     SCALE (unsigned long)(POWER * POWER)
#define LEAF_SIZE (unsigned long)(BASE * BASE)

#define L1_TREE_BASE (unsigned long)(BASE * (2ul))
#define L1_TREE_SIZE (unsigned long)(L1_TREE_BASE * L1_TREE_BASE)

#define L2_TREE_BASE (unsigned long)(BASE * (2ul * 2ul))
#define L2_TREE_SIZE (unsigned long)(L2_TREE_BASE * L2_TREE_BASE)


@implementation SparseBitArrayTest2D

- (void)setUp {
    [super setUp];
    _array = [[BASparseBitArray alloc] initWithBase:BASE power:POWER];
}

- (void)tearDown {
    [super tearDown];
    _array = nil;
}

- (void)test01 {
    STAssertEquals(_array.scale, SCALE, @"Wrong tree scale");
    STAssertEquals(_array.leafSize, LEAF_SIZE, @"Wrong leaf size");

    STAssertEquals(_array.level, 1ul, @"Wrong tree root level");
    STAssertEquals(_array.treeBase, L1_TREE_BASE, @"Wrong tree base");
    STAssertEquals(_array.treeSize, L1_TREE_SIZE, @"Wrong tree size");
    
    [_array setBitAtX:2*BASE y:0];
    
    STAssertEquals(_array.level, 2ul, @"Wrong tree root level");
    STAssertEquals(_array.treeBase, L2_TREE_BASE, @"Wrong tree base");
    STAssertEquals(_array.treeSize, L2_TREE_SIZE, @"Wrong tree size");
}

- (void)test02 {
    [_array setBitAtX:0 y:0];
    STAssertTrue([_array bitAtX:0 y:0], @"failed to confirm bit set at (0,0)");
    [_array setBitAtX:1 y:0];
    STAssertTrue([_array bitAtX:1 y:0], @"failed to confirm bit set at (-1,0)");
    [_array setBitAtX:0 y:1];
    STAssertTrue([_array bitAtX:0 y:1], @"failed to confirm bit set at (0,-1)");
    [_array setBitAtX:1 y:1];
    STAssertTrue([_array bitAtX:1 y:1], @"failed to confirm bit set at (-1,-1)");
}

- (void)test03 {
    [_array setBitAtX:7 y:7];
    STAssertTrue([_array bitAtX:7 y:7], @"failed to confirm bit set at (7,7)");
    [_array setBitAtX:8 y:7];
    STAssertTrue([_array bitAtX:8 y:7], @"failed to confirm bit set at (-8,7)");
    [_array setBitAtX:7 y:8];
    STAssertTrue([_array bitAtX:7 y:8], @"failed to confirm bit set at (7,-8)");
    [_array setBitAtX:8 y:8];
    STAssertTrue([_array bitAtX:8 y:8], @"failed to confirm bit set at (-8,-8)");
}

- (void)test04 {
    [_array setBitAtX:0 y:0];
    [_array setBitAtX:1023 y:1023];
    [_array setAll];
    [_array clearAll];
}


- (void)test99 {
    
    uint32_t size = (uint32_t)powi(4, TABLE_SIZE-1);
    uint32_t x, y;
    LeafCoordinatesForIndex2D(size-1, &x, &y);
    NSLog(@"Last 2D coordinate for tree of size %d: {%d,%d}", size, x, y);
}

@end
