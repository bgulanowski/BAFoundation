//
//  BABitArrayTester.h
//  BAFoundation
//
//  Created by Brent Gulanowski on 11-03-22.
//  Copyright 2011 Bored Astronaut. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BABitArray.h"


@interface BABitArrayTester : XCTestCase {

}

@end


@interface BABitArray (TestingAdditions)
// up to, but not including, max
- (void)setDiagonalReverse:(BOOL)reverse min:(NSUInteger)min max:(NSUInteger)max;
- (void)setRow:(NSUInteger)row min:(NSUInteger)min max:(NSUInteger)max;
- (void)setColumn:(NSUInteger)column min:(NSUInteger)min max:(NSUInteger)max;
@end
