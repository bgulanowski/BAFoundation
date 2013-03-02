//
//  SparseBitArrayTestBasic.m
//  MapTest
//
//  Created by Brent Gulanowski on 12-10-26.
//  Copyright (c) 2012 Lichen Labs. All rights reserved.
//

#import "SparseBitArrayTestBasic.h"

#import "BASparseBitArray.h"


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
    
    STAssertEquals(LeafIndexFor2DCoordinates(0, 0, 1), 0u, @"");
    STAssertEquals(LeafIndexFor2DCoordinates(0, 0, 2), 0u, @"");
    STAssertEquals(LeafIndexFor2DCoordinates(0, 0, 4), 0u, @"");
    STAssertEquals(LeafIndexFor2DCoordinates(0, 0, 8), 0u, @"");
    STAssertEquals(LeafIndexFor2DCoordinates(0, 0, 16), 0u, @"");
    STAssertEquals(LeafIndexFor2DCoordinates(0, 0, 32), 0u, @"");
    
    STAssertEquals(LeafIndexFor2DCoordinates(0, 3, 1), 10u, @"");
    STAssertEquals(LeafIndexFor2DCoordinates(3, 0, 1),  5u, @"");
    STAssertEquals(LeafIndexFor2DCoordinates(3, 3, 1), 15u, @"");
    STAssertEquals(LeafIndexFor2DCoordinates(0, 4, 1), 32u, @"");
    STAssertEquals(LeafIndexFor2DCoordinates(4, 0, 1), 16u, @"");
    STAssertEquals(LeafIndexFor2DCoordinates(4, 4, 1), 48u, @"");
    STAssertEquals(LeafIndexFor2DCoordinates(7, 5, 1), 55u, @"");
    STAssertEquals(LeafIndexFor2DCoordinates(5, 7, 1), 59u, @"");
    
    uint32_t x, y;
    
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
    for(uint32_t i=0; i<512; ++i)
        for(uint32_t j=0; j<512; ++j)
            LeafIndexFor2DCoordinates(j, i, 1);
}

- (void)testSpeed02 {
    uint32_t x, y;
    for(uint32_t i=0; i<262144; ++i)
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

@end
