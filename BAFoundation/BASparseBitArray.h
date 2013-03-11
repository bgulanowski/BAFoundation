//
//  SparseBitArray.h
//  Dungineer
//
//  Created by Brent Gulanowski on 12-10-25.
//  Copyright (c) 2012 Lichen Labs. All rights reserved.
//

#import <BAFoundation/BASparseArray.h>

#import <BAFoundation/BABitArray.h>


@interface BASparseBitArray : BASparseArray<NSCoding, BABitArray> {
    
    BABitArray *_bits; // storage for leaf data
    
    SparseArrayToggle _toggleBlock;
}

@property (nonatomic, strong) SparseArrayToggle toggleBlock;
@property (nonatomic, strong) BABitArray *bits;

// power 2 conveniences
- (BOOL)bitAtX:(NSUInteger)x y:(NSUInteger)y;
- (void)updateBitAtX:(NSUInteger)x y:(NSUInteger)y set:(BOOL)set;
- (void)setBitAtX:(NSUInteger)x y:(NSUInteger)y;
- (void)clearBitAtX:(NSUInteger)x y:(NSUInteger)y;

// power 3 conveniences
- (BOOL)bitAtX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z;
- (void)updateBitAtX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z set:(BOOL)set;
- (void)setBitAtX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z;
- (void)clearBitAtX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z;

// Add new category to BAScene and move there
//- (void)setRegion:(BARegioni)region;

@end
