//
//  BANoiseMakerTester.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 11/16/2013.
//  Copyright (c) 2013 Lichen Labs. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BANoise.h"

static inline BOOL boundary(double x, double y, double z) {
	return x == floor(x) && y == floor(y) && z == floor(z);
}

static inline double fade(double t) { return t * t * t * (t * (t * 6 - 15) + 10); }

static inline double lerp(double t, double a, double b) { return a + t * (b - a); }

static inline double grad(int hash, double x, double y, double z) {
	
	int h = hash & 15;
	double u = h < 8 ? x : y;
	double v = h < 4 ? y : h==12||h==14 ? x : z;
	
	return ((h&1) == 0 ? u : -u) + ((h&2) == 0 ? v : -v);
}

static int permutation[] = { 151,160,137,91,90,15,
	131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,
	21,10,23,190,6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,
	35,11,32,57,177,33,88,237,149,56,87,174,20,125,136,171,168,68,175,
	74,165,71,134,139,48,27,166,77,146,158,231,83,111,229,122,60,211,133,
	230,220,105,92,41,55,46,245,40,244,102,143,54,65,25,63,161,1,216,
	80,73,209,76,132,187,208,89,18,169,200,196,135,130,116,188,159,86,
	164,100,109,198,173,186,3,64,52,217,226,250,124,123,5,202,38,147,
	118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,223,
	183,170,213,119,248,152,2,44,154,163,70,221,153,101,155,167,43,
	172,9,129,22,39,253,19,98,108,110,79,113,224,232,178,185,112,104,
	218,246,97,228,251,34,242,193,238,210,144,12,191,179,162,241,81,51,
	145,235,249,14,239,107,49,192,214,31,181,199,106,157,184,84,204,176,
	115,121,50,45,127,4,150,254,138,236,205,93,222,114,67,29,24,72,243,
	141,128,195,78,66,215,61,156,180
};

static const double divisions = 16.;
static const double increments = 1./divisions;
static const double start = 0.;
static const double finish = 4.;

static __strong NSData *sampleData;

@interface BANoiseMakerTester : XCTestCase

+ (double)evaluateX:(double)x Y:(double)y Z:(double)z;
+ (NSData *)sampleData;

@end

@implementation BANoiseMakerTester

+ (void)initialize {
	if (self == [BANoiseMakerTester class]) {
		sampleData = [[self sampleData] retain];
	}
}

+ (NSData *)sampleData {
	
	if (sampleData) {
		return sampleData;
	}
	
	size_t size = sizeof(double) * (size_t)(pow((finish-start)/increments, 3.));
	
	NSAssert((int)(4*16*4*16*4*16*sizeof(double)) == (int)size, @"size miscalculation");
	
	NSString *path = [[NSString stringWithFormat:@"~/Desktop/NoiseSampleData (%.0f-%.0f) by %.0fths.bin", start, finish, divisions] stringByExpandingTildeInPath];
	NSError *error = nil;
	NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingMapped error:&error];
	
	if (!data) {
		
		NSLog(@"Error reading file '%@': %@", path, error);
		
		double *samples = malloc(size);
		double *cursor = samples;
		
		NSAssert(samples != NULL, @"memory allocation failed");
		
		for (double x = start; x < finish; x += increments) {
			for (double y = start; y < finish; y += increments) {
				for (double z = start; z < finish; z += increments) {
					
					double sample = [self evaluateX:x Y:y Z:z];
					
					NSAssert(sample == 0. || sample == 0.5 || !boundary(x, y, z), @"Unexpected sample value (%.3f) at integral (%.1f,%.1f,%.1f); should be zero", x, y, z, sample);
					
					*cursor = sample;
					++cursor;
				}
			}
		}
		
		NSAssert((size_t)(cursor - samples) == size/sizeof(double), @"sample count miscalculation");
		
		data = [NSData dataWithBytesNoCopy:samples length:size freeWhenDone:YES];
		
		[data writeToFile:path atomically:NO];
	}
	
	return data;
}

+ (double)evaluateX:(double)x Y:(double)y Z:(double)z {
	
	static dispatch_once_t onceToken;
	static int p[512];
	dispatch_once(&onceToken, ^{
		for(unsigned i = 0; i < 256 ; i++)
			p[256+i] = p[i] = permutation[i];
	});
	
	struct {
		int X; int Y; int Z;
		double u; double v; double w;
		
		int A; int AA; int AB;
		double gAA0; double gAA1; double gAB0; double gAB1;
		
		int B; int BA; int BB;
		double gBA0; double gBA1; double gBB0; double gBB1;
		
		double lerp1; double lerp2; double lerp3; double lerp4; double lerp5; double lerp6; double lerp7;
	} data = {};
	
	data.X = (int)floor(x) & 255; data.Y = (int)floor(y) & 255; data.Z = (int)floor(z) & 255;
	
	x -= floor(x); y -= floor(y); z -= floor(z);
	
	data.u = fade(x); data.v = fade(y); data.w = fade(z);
	
	data.A  = p[data.X  ]+data.Y; data.AA = p[data.A  ]+data.Z; data.AB = p[data.A+1]+data.Z;
	
	data.gAA0 = grad(p[data.AA  ],   x,   y,   z);
	data.gAA1 = grad(p[data.AA+1],   x,   y, z-1);
	data.gAB0 = grad(p[data.AB  ],   x, y-1,   z);
	data.gAB1 = grad(p[data.AB+1],   x, y-1, z-1);
	
	data.B  = p[data.X+1]+data.Y;
	data.BA = p[data.B  ]+data.Z;
	data.BB = p[data.B+1]+data.Z;
	
	data.gBA0 = grad(p[data.BA  ], x-1,   y,   z);
	data.gBA1 = grad(p[data.BA+1], x-1,   y, z-1);
	data.gBB0 = grad(p[data.BB  ], x-1, y-1,   z);
	data.gBB1 = grad(p[data.BB+1], x-1, y-1, z-1);
	
	data.lerp1 = lerp( data.u, data.gAA0, data.gBA0);
	data.lerp2 = lerp( data.u, data.gAA1, data.gBA1);
	
	data.lerp3 = lerp( data.u, data.gAB0, data.gBB0);
	data.lerp4 = lerp( data.u, data.gAB1, data.gBB1);
	
	data.lerp5 = lerp( data.v, data.lerp1, data.lerp3);
	data.lerp6 = lerp( data.v, data.lerp2, data.lerp4);
	
	data.lerp7 = lerp( data.w, data.lerp5, data.lerp6);
	
	return data.lerp7;
}

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testBasicSampleAccuracy
{
	BANoise *noise = [[BANoise alloc] init];
	
	XCTAssertNotNil(noise, @"BANoiseMaker returned nil from init");
	
	double *samples = (double *)[sampleData bytes];
	double *sampleCursor = samples;
	
	BOOL breakout = NO;
	NSUInteger zeroCount = 0;
	
	for (double x = start; x < finish && !breakout; x += increments) {
		for (double y = start; y < finish && !breakout; y += increments) {
			for (double z = start; z < finish && !breakout; z += increments) {
				double noiseSample = [noise evaluateX:x Y:y Z:z];
				XCTAssertEqual(noiseSample, *sampleCursor, @"Mismatched sample data for (%f,%f,%f)", x, y, z);
				breakout = *sampleCursor != noiseSample;
				sampleCursor++;
				if (noiseSample == 0.) {
					++zeroCount;
				}
			}
		}
	}
	
	NSLog(@"%d out of %d samples with zero value", (int)zeroCount, (int)([sampleData length]/sizeof(double)));
}

@end
