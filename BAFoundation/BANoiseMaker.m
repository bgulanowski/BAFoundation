//
//  BANoiseMaker.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 11-01-20.
//  Copyright 2011 Bored Astronaut. All rights reserved.
//

#import <BAFoundation/BANoiseMaker.h>

#include <math.h>

#import <BAFoundation/BASampleArray.h>



@implementation BANoiseMaker

- (void)dealloc {
    [data release];
    data = nil;
    [super dealloc];
}

- (id)init {
	return [self initWithSeed:0];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if(self) {
        
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)initWithSeed:(unsigned)seed {
    self = [super init];
    if(self) {
        
        p = malloc(sizeof(int)*512);
        
        if(seed > 0) {

            int permute[256];
            char state[256];
            
            initstate(seed, state, 256);
            
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
                p[256+i] = p[i] = BADefaultPermutation[i];
        }
        data = [[NSData alloc] initWithBytesNoCopy:p length:sizeof(int)*512 freeWhenDone:YES];
    }
    return self;
}

- (double)evaluateX:(double)x Y:(double)y Z:(double)z {
	return BANoiseEvaluate(p, x, y, z);
}

- (double)blendX:(double)x Y:(double)y Z:(double)z octaves:(unsigned)octave_count persistence:(double)persistence {
	return BANoiseBlend(p, x, y, z, octave_count, persistence);
}

- (double *)blendX:(double)x Y:(double)y Z:(double)z
             width:(unsigned)w height:(unsigned)h depth:(unsigned)d
         increment:(double)increment octaves:(unsigned)octave_count persistence:(double)persistence {
    
    NSAssert(w > 0 && h > 0 && d > 0, @"all dimensions of sample block must be greater than zero");
    
    double *result = malloc(sizeof(double)*h*w*d);
    
    if(!result)
        exit(1);
    
    unsigned index = 0;
    
    double ix = x, iy = y, iz = z;
    
    for (unsigned k=0; k<d; ++k) {
        for (unsigned j=0; j<h; ++j) {
            for (unsigned i=0; i<w; ++i) {
                result[index++] = BANoiseBlend(p, ix, iy, iz, octave_count, persistence);
                ix += increment;
            }
            iy += increment;
            ix = x;
        }
        iz += increment;
        iy = y;
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
