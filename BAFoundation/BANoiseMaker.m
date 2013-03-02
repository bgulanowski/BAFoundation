//
//  BANoiseMaker.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 11-01-20.
//  Copyright 2011 Bored Astronaut. All rights reserved.
//

#import "BANoiseMaker.h"

#include <math.h>

static inline double fade(double t) { return t * t * t * (t * (t * 6 - 15) + 10); }

static inline double lerp(double t, double a, double b) { return a + t * (b - a); }

static inline double grad(int hash, double x, double y, double z) {
	
	int h = hash & 15;
	double u = h < 8 ? x : y;
	double v = h < 4 ? y : h==12||h==14 ? x : z;
	
	return ((h&1) == 0 ? u : -u) + ((h&2) == 0 ? v : -v);
}



//static long p_seed = 1295704232; // `date +%s` as of a few seconds ago
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

@implementation BANoiseMaker

- (id)init {
	self = [self initWithSeed:0];
	if(self) {
	}
	return self;
}

- (id)initWithSeed:(unsigned)aSeed {
    self = [super init];
    if(self) {
        seed = aSeed;
        if(seed > 0) {

            int permute[256];
            
            srandom(seed);
            
            for(int i=0; i<256; i++)
                permute[i]=i;
            for(int i=0; i<(2<<10); ++i) {
                int a = random()&255, b=random()&255;
                int temp = permute[a];
                permute[a]=permute[b];
                permute[b]=temp;
            }
            for(int i=0; i<256; ++i)
                p[256+i] = p[i] = permute[i]; 		
        }
        else {
            for(unsigned i = 0; i < 256 ; i++) 
                p[256+i] = p[i] = permutation[i]; 		
        }
    }
    return self;
}

- (double)evaluateX:(double)x Y:(double)y Z:(double)z {
	
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

- (double)blendX:(double)x Y:(double)y Z:(double)z octaves:(unsigned)octave_count persistence:(double)persistence function:(int)func {
	
	double component = 0, result = (1==func ? x : 0), frequency = 0, amplitude = 0;
	
	NSAssert(persistence <= 1, @"Persistence cannot exceed 1");
	
	for(unsigned i=0; i<octave_count; i++) {
		frequency = 1<<i;
		amplitude = pow(persistence, i);
		component = [self evaluateX:x*frequency Y:y*frequency Z:z*frequency] * amplitude;
		result += component;
	}
	
	switch (func) {
		case 1:
		case 2:
			return sin(result);
		case 3:
			return (result + [self evaluateX:1.3*y+0.1 Y:1.9*y+0.7 Z:1.3*x+1.1])/2.0f;
		default:
			break;
	}
	return result;
}

+ (BANoiseMaker *)randomNoise {
    srandom(time(NULL));
    return [[[self alloc] initWithSeed:(unsigned)random()] autorelease];
}

@end


#if NOISE_TEST
int main( int argc, char *argv[] ) {

	BANoiseMaker *nm = [[BANoiseMaker alloc] init];
	double offset = 8.0f, increment = 1.0f/64, count = 32, limit = offset+(count*increment);
	
	for(double x=offset; x<limit; x+=increment)
//		for(double y=0; y<1; y+=0.2)
//			for(double z=0; z<1; z+=0.2)
				NSLog(@"%.3f %.3f %.3f: %f", x, 0.0, 0.0, [nm blendX:x Y:0 Z:0 octaves:3 persistence:0.5 function:3]);
	
	return 0;
}

#endif
