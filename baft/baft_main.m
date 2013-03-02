/*
 *  baft_main.m
 *  BAFoundation
 *
 *  Created by Brent Gulanowski on 11-03-23.
 *  Copyright 2011 Bored Astronaut. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>

#import "BAFT.h"

int main(int argc, char *argv[])
{	
	BAFT *baft = [[BAFT alloc] init];
	
	return [baft run];
}
