//
//  SparseBitArrayTestBasic.m
//  MapTest
//
//  Created by Brent Gulanowski on 12-10-26.
//  Copyright (c) 2012 Lichen Labs. All rights reserved.
//

#import "SparseBitArrayTestBasic.h"

#import "BASparseBitArray.h"
#import "BAFunctions.h"


@implementation SparseBitArrayTestBasic

- (void)setUp {
    [super setUp];
    _array = [[BASparseBitArray alloc] initWithBase:8 power:1];
}

- (void)tearDown {
    _array = nil;
    [super tearDown];
}

- (void)test01 {
    STAssertNotNil(_array, @"Failed to create sparse bit array");
    
    STAssertEquals(NextPowerOf2(1), (uint32_t)1, @"power of 2 calculator broken");
    
    for(uint32_t i=2; i<31; ++i)
        STAssertEquals(NextPowerOf2((1<<i)-1), (uint32_t)(1<<i), @"power of 2 calculator broken");
    
    for(uint32_t i=0; i<31; ++i) {
        uint32_t e = (uint32_t)(1<<(i+1));
        uint32_t a = NextPowerOf2((1<<i)+1);
        STAssertEquals(a, e, @"power of 2 calculator broken");
    }
    
    STAssertEquals(LeafIndexFor2DCoordinates(0, 0, 1), (NSUInteger) 0, @"");
    STAssertEquals(LeafIndexFor2DCoordinates(0, 0, 2), (NSUInteger) 0, @"");
    STAssertEquals(LeafIndexFor2DCoordinates(0, 0, 4), (NSUInteger) 0, @"");
    STAssertEquals(LeafIndexFor2DCoordinates(0, 0, 8), (NSUInteger) 0, @"");
    STAssertEquals(LeafIndexFor2DCoordinates(0, 0, 16), (NSUInteger) 0, @"");
    STAssertEquals(LeafIndexFor2DCoordinates(0, 0, 32), (NSUInteger) 0, @"");
    
    STAssertEquals(LeafIndexFor2DCoordinates(0, 3, 1), (NSUInteger) 10, @"");
    STAssertEquals(LeafIndexFor2DCoordinates(3, 0, 1), (NSUInteger) 5, @"");
    STAssertEquals(LeafIndexFor2DCoordinates(3, 3, 1), (NSUInteger) 15, @"");
    STAssertEquals(LeafIndexFor2DCoordinates(0, 4, 1), (NSUInteger) 32, @"");
    STAssertEquals(LeafIndexFor2DCoordinates(4, 0, 1), (NSUInteger) 16, @"");
    STAssertEquals(LeafIndexFor2DCoordinates(4, 4, 1), (NSUInteger) 48, @"");
    STAssertEquals(LeafIndexFor2DCoordinates(7, 5, 1), (NSUInteger) 55, @"");
    STAssertEquals(LeafIndexFor2DCoordinates(5, 7, 1), (NSUInteger) 59, @"");
    
    NSUInteger x, y;
    
    LeafCoordinatesForIndex2D(3, &x, &y);
    STAssertTrue(x == 1 && y == 1, @"Reverse coordinates failed; expected (3,0); actual: (%u,%u)", x, y);
    
    LeafCoordinatesForIndex2D(5, &x, &y);
    STAssertTrue(x == 3 && y == 0, @"Reverse coordinates failed; expected (3,0); actual: (%u,%u)", x, y);
    
    LeafCoordinatesForIndex2D(10, &x, &y);
    STAssertTrue(x == 0 && y == 3, @"Reverse coordinates failed; expected (0,3); actual: (%u,%u)", x, y);
    
    LeafCoordinatesForIndex2D(16, &x, &y);
    STAssertTrue(x == 4 && y == 0, @"Reverse coordinates failed; expected (4,0); actual: (%u,%u)", x, y);
    
    LeafCoordinatesForIndex2D(25, &x, &y);
    STAssertTrue(x == 5 && y == 2, @"Reverse coordinates failed; expected (5,2); actual: (%u,%u)", x, y);
    
    LeafCoordinatesForIndex2D(41, &x, &y);
    STAssertTrue(x == 1 && y == 6, @"Reverse coordinates failed; expected (1,6); actual: (%u,%u)", x, y);
    
    LeafCoordinatesForIndex2D(48, &x, &y);
    STAssertTrue(x == 4 && y == 4, @"Reverse coordinates failed; expected (4,4); actual: (%u,%u)", x, y);
    
    LeafCoordinatesForIndex2D(196, &x, &y);
    STAssertTrue(x == 10 && y == 8, @"Reverse coordinates failed; expected (10,8); actual: (%u,%u)", x, y);
    
    LeafCoordinatesForIndex2D(315, &x, &y);
    STAssertTrue(x == 21 && y == 7, @"Reverse coordinates failed; expected (8,10); actual: (%u,%u)", x, y);
}

- (void)testSpeed01 {
    for(NSUInteger i=0; i<512; ++i)
        for(NSUInteger j=0; j<512; ++j)
            LeafIndexFor2DCoordinates(j, i, 1);
}

- (void)testSpeed02 {
    NSUInteger x, y;
    for(NSUInteger i=0; i<262144; ++i)
        LeafCoordinatesForIndex2D(i, &x, &y);
}

- (void)test02 {
    [_array setBit:0];
    STAssertTrue([_array bit:0], @"Bit 0 doesn't match");
    [_array setBit:7];
    STAssertTrue([_array bit:7], @"Bit 7 doesn't match");
}

- (void)test03 {
    [_array setBit:8];
    STAssertTrue([_array bit:8], @"Bit 0 doesn't match");
}

- (void)test04 {
    
    NSUInteger treeBase = _array.treeBase;
    NSUInteger leafBase = _array.base;

    NSUInteger e = 0;

    for(NSUInteger i=0; i<treeBase; i+=leafBase) {
        [_array setBit:i];
        ++e;
    }
    
    __block NSUInteger nodeCount = 0;
    __block NSUInteger leafCount = 0;

    [_array walkChildren:^BOOL(BASparseArray *sparseArray, NSIndexPath *indexPath, NSUInteger *offset) {
//        NSLog(@"%@ - %d", indexPath, (int)&offset);
        ++nodeCount;
        if(0 == sparseArray.level)
            ++leafCount;
        return NO;
    }];
    
    NSLog(@"Count: %d nodes, %d leaves", (int)nodeCount, (int)leafCount);
    STAssertEquals(leafCount, e, @"Wrong leaf count. Expected: %d. Actual: %d", e, leafCount);
}

@end
