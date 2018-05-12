//
//  BAFBFunctions.h
//  BAFB
//
//  Created by Brent Gulanowski on 2018-05-07.
//  Copyright © 2018 Lichen Labs. All rights reserved.
//

#ifndef BAFBFunctions_h
#define BAFBFunctions_h

void *CreateNoise(unsigned seed, int octaves, float persistence);
void DestroyNoise(void *noise);
float EvalNoise(void *noise, float x, float y, float z);

#endif
