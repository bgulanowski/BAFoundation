//
//  BAFT.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 11-03-23.
//  Copyright 2011 Bored Astronaut. All rights reserved.
//

#import "BAFT.h"

#import "BABitArray.h"


@implementation BAFT

- (int)run {
	
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	BABitArray *ba = [BABitArray bitArray64];
	
	[ba setRange:NSMakeRange(3, 3)];
	
	NSLog(@"%ld %ld", (unsigned long)[ba firstSetBit], (unsigned long)[ba lastSetBit]);
	
	[pool drain];
	
	return 0;
}

@end
