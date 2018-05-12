//
//  BAFBFunctions.c
//  BAFB
//
//  Created by Brent Gulanowski on 2018-05-07.
//  Copyright © 2018 Lichen Labs. All rights reserved.
//

#include "BAFBFunctions.h"

#import <BAFoundation/BAFoundation.h>

void *CreateNoise(unsigned seed, int octaves, float persistence) {
    BANoise *noise = [BASimplexNoise noiseWithSeed:0 octaves:octaves persistence:persistence transform:nil];
    return (void *)CFBridgingRetain(noise);
}

void DestroyNoise(void *noise) {
    CFBridgingRelease(noise);
}

float EvalNoise(void *noise, float x, float y, float z) {
    return [(__bridge BANoise *)noise evaluateX:x Y:y Z:z];
}
