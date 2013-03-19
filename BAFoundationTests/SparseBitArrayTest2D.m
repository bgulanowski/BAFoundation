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

- (void)test05Walk {
    
    NSUInteger treeBase = _array.treeBase*2;
    NSUInteger leafBase = _array.base;
    
    NSUInteger e = 0;
    
    for(NSUInteger i=0; i<treeBase; i+=leafBase) {
        for (NSUInteger j=0; j<treeBase; j+=leafBase) {
            [_array setBitAtX:j y:i];
            ++e;
        }
    }
    
    __block NSUInteger nodeCount = 0;
    __block NSUInteger leafCount = 0;
    
    [_array walkChildren:^BOOL(BASparseArray *sparseArray, NSIndexPath *indexPath, NSUInteger *offset) {
//        NSLog(@"%@ - {%d,%d}", indexPath, (int)*offset, (int)*(offset+1));
        ++nodeCount;
        if(0 == sparseArray.level)
            ++leafCount;
        return NO;
    }];
    
//    NSLog(@"Count: %d nodes, %d leaves", (int)nodeCount, (int)leafCount);
    STAssertEquals(leafCount, e, @"Wrong leaf count. Expected: %d. Actual: %d", e, leafCount);
}

- (void)test06String {
    
    NSUInteger treeBase = _array.treeBase;
    
    for (NSUInteger i=0; i<treeBase; ++i) {
        [_array setBitAtX:i y:i];
        [_array setBitAtX:treeBase-1 y:i];
    }

    NSMutableArray *strings = [NSMutableArray array];
    char *str = malloc(sizeof(char)*(treeBase+1));
    
    str[treeBase] = '\0';
    
    for (NSUInteger i=0; i<treeBase; ++i) {
        memset(str, '_', treeBase);
        str[i] = 'S';
        str[treeBase-1] = 'S';
        [strings insertObject:[NSString stringWithCString:str encoding:NSASCIIStringEncoding] atIndex:0];
    }
    
    NSString *e = [strings componentsJoinedByString:@"\n"];
    NSString *a = [_array stringForRect];
    
    STAssertEqualObjects(a, e, @"String creation failed.");
}

- (void)testWriteRect {
    
    NSRect setRect = NSMakeRect(8, 8, 32, 32);
    NSRect clrRect = NSMakeRect(16, 16, 16, 16);
    
    [_array setRect:setRect];
    [_array clearRect:clrRect];
    
    STAssertEquals([_array count], (NSUInteger) (32*32 - 16*16), @"count failed");
    
    NSString *string = [_array stringForRect];
    
    STAssertEquals([string length], [_array treeSize]+[_array treeBase]-1, @"whaaa");
    
    NSRect rect = NSMakeRect(0, 0, BASE, BASE);
    id<BABitArray2D> ba = [_array subArrayWithRect:rect];
    
    STAssertEquals([ba count], (NSUInteger)8*8, @"Wrong count");
    
    string = [_array stringForRect:rect];
    NSString *other = [ba stringForRect];
    
    STAssertNotNil(ba, @"Failed to create subarray");
    
    STAssertEqualObjects(other, string, @"string creation failed");
    
    rect = NSMakeRect(4, 4, 20, 10);
    
    NSUInteger length = rect.size.width * rect.size.height;
    NSRect intersection = NSIntersectionRect(rect, setRect);
    NSUInteger count = intersection.size.width*intersection.size.height;

    ba = [_array subArrayWithRect:rect];
    STAssertEquals(ba.length, length, @"wrong length");
    STAssertEquals(ba.count, count, @"wrong count");

    NSUInteger stringLength = length + rect.size.height - 1;

    string = [_array stringForRect:rect];
    STAssertEquals([string length], stringLength, @"wrong string length");

    other = [ba stringForRect];
    STAssertEquals([other length], stringLength, @"wrong string length");
    
    STAssertEqualObjects(string, other, @"string creation failed");
}

- (void)test99 {
    
    uint32_t size = (uint32_t)powi(4, TABLE_SIZE-1);
    uint32_t x, y;
    LeafCoordinatesForIndex2D(size-1, &x, &y);
    NSLog(@"Last 2D coordinate for tree of size %d: {%d,%d}", size, x, y);
}

@end
