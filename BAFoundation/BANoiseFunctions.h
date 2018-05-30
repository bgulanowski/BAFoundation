//
//  BANoiseFunctions.h
//  BAFoundation
//
//  Created by Brent Gulanowski on 2018-05-16.
//  Copyright © 2018 Lichen Labs. All rights reserved.
//

#import <BAFoundation/BANoiseTypes.h>

extern const int BADefaultPermutation[512];

extern double BANoiseEvaluate(const int *p, double x, double y, double z);
extern double BANoiseBlend(const int *p, double x, double y, double z, double octave_count, double persistence);

double BASimplexNoise2DEvaluate(const int *p, const int *pmod, double xin, double  yin);
double BASimplexNoise3DEvaluate(const int *p, const int *pmod, double xin, double  yin, double zin);
extern double BASimplexNoise3DBlend(const int *p, const int *mod, double x, double y, double z, double octave_count, double persistence);
extern double BASimplexNoiseMax(double octave_count, double persistence);

extern void BANoiseIterate(BANoiseEvaluator evaluator, BANoiseIteratorBlock block, BANoiseRegion region, double inc);
