//
//  BABitArray+Rectangles.h
//  BAFoundation
//
//  Created by Brent Gulanowski on 2015-02-08.
//  Copyright (c) 2015 Lichen Labs. All rights reserved.
//

#import <BAFoundation/BABitArray.h>


#define BARectArea(rect) ((rect).size.width * (rect).size.height)
#define BARectPerimeter(rect) ((rect).size.width * 2 + (rect).size.height * 2)


NS_INLINE CGRect BABestRect(CGRect r1, CGRect r2) {
	
	CGFloat r1a = BARectArea(r1);
	CGFloat r1p = BARectPerimeter(r1);
	CGFloat r2a = BARectArea(r2);
	CGFloat r2p = BARectPerimeter(r2);
	
	if(r2a > r1a || (r2a == r1a && r1p > r2p))
		return r2;
	else
		return r1;
}

NS_INLINE CGRect BARectSquare(CGRect rect) {
	if(rect.size.width < rect.size.height)
		rect.size.height = rect.size.width;
	else if(rect.size.height < rect.size.width)
		rect.size.width = rect.size.height;
	return rect;
}

@interface BABitArray (Rectangles)

// caller must free returned pointer
- (UInt16 *)histogram2d;
- (UInt16 *)inverseHistogram2d;

- (void)iterateEmptyRectsWithBlock:(BOOL (^)(CGRect))block;

- (CGRect)largestEmptyRect;
- (CGRect)largestEmptySquare;

@end
