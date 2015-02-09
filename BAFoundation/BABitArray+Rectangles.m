//
//  BABitArray+Rectangles.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 2015-02-08.
//  Copyright (c) 2015 Lichen Labs. All rights reserved.
//

#import "BABitArray+Rectangles.h"

@implementation BABitArray (Rectangles)

- (UInt16 *)histogram2dInverse:(BOOL)inverse {
	
	UInt16 const width = size2d.width;
	UInt16 const height = size2d.height;
	
	NSAssert((NSUInteger)width*height == length, @"wrong size info");
	
	UInt16 *array = malloc(sizeof(UInt16)*self.length);
	UInt16 *cursor = array;
	BOOL *bits = malloc(sizeof(BOOL)*width);
	
	NSRange range = NSMakeRange(0, width);
	UInt16 current;
	
	for (UInt16 i=0; i<height; ++i) {
		
		current = 0;
		
		[self readBits:bits range:range];
		range.location += width;
		
		for (UInt16 j=0; j<width; ++j) {
			
			if((inverse && !bits[j]) || (!inverse && bits[j]))
				++current;
			else
				current = 0;
			
			*cursor++ = current;
		}
	}
	
	free(bits);
	
	return array;
}

- (UInt16 *)histogram2d {
	return [self histogram2dInverse:NO];
}

- (UInt16 *)inverseHistogram2d {
	return [self histogram2dInverse:YES];
}

- (void)iterateEmptyRectsWithBlock:(BOOL (^)(CGRect))block {
	
	UInt16 *histogram = [self inverseHistogram2d];
	
	NSInteger w = size2d.width;
	NSInteger h = size2d.height;
	
	CGRect *activeRects = malloc(sizeof(CGRect)*(h+1));
	*activeRects = CGRectZero;
	
	for (NSInteger j=w-1; j>=0; --j) {
		
		CGRect *prev = activeRects;
		
		for (NSInteger i=0; i<h; ++i) {
			
			CGFloat currWidth = (CGFloat)histogram[i*w+j];
			
			if(currWidth == prev->size.height) {
				++prev->size.height;
				continue;
			}
			
			CGRect curr = CGRectMake((CGFloat)j+1-currWidth, (CGFloat)i, currWidth, 1);
			CGFloat d = 0;
			
			// Note that the currWidth == prev.size.width only matters after first iteration
			while(currWidth <= prev->size.width && prev->size.width > 0) {
				
				CGFloat dh = prev->size.height;
				
				prev->size.height += d;
				if(block(*prev)) goto end;
				d += dh;
				curr.size.height += dh;
				curr.origin.y -= dh;
				--prev;
			}
			
			++prev;
			*prev = curr;
		}
		
		while (prev > activeRects) {
			if(block(*prev)) goto end;
			--prev;
			prev->size.height = h - prev->origin.y;
		}
	}
	
end:
	free(histogram);
	free(activeRects);
}

- (CGRect)largestEmptyRect {
	
	// Quick return for full or empty area
	if(count == length)
		return CGRectZero;
	else if(count == 0)
		return CGRectMake(0, 0, size2d.width, size2d.height);
	
	__block CGRect best = CGRectZero;
	
	best.origin = CGPointMake(-1, -1);
	best.size = CGSizeZero;
	
	[self iterateEmptyRectsWithBlock:^(CGRect curr) {
		if(BARectArea(curr) > BARectArea(best)) {
			best = curr;
		}
		return NO;
	}];
	
	if(CGRectIsEmpty(best))
		best = CGRectZero;
	
	return best;
}

- (CGRect)largestEmptySquare {
	
	__block CGRect best = CGRectZero;
	
	best.origin = CGPointMake(-1, -1);
	best.size = CGSizeZero;
	
	[self iterateEmptyRectsWithBlock:^(CGRect curr) {
		CGRect square = BARectSquare(curr);
		if(square.size.width > best.size.width)
			best = square;
		return NO;
	}];
	
	if(CGRectIsEmpty(best))
		best = CGRectZero;
	
	return best;
}

@end
