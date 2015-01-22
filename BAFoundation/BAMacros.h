/*
 *  BAMacros.h
 *  ToyWorld
 *
 *  Created by Brent Gulanowski on 2005-6-14.
 *  Copyright 2005 Bored Astronaut Software. All rights reserved.
 *
 */


#define sine sinf
#define cosine cosf
#define absolute fabsf
#define BAInt long
#define BAUInt unsigned long
#define NAN_OFFSET LONG_MAX+1  // -1 signed long
#define ULPS_DELTA 0x0fff
#ifdef FLT_EPSILON
#define EPSILON FLT_EPSILON
#else
#define EPSILON __FLT_EPSILON__
#endif

#define BALog(x) NSLog(@"%@ - %@\n\t%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (x))

#define BARandomLongLong()             (((long long)random() << 32) | (long long)random())
#define BARandomFloat()                ((float)random()/(float)INT_MAX)
#if CGFLOAT_IS_DOUBLE
#define BARandomCGFloat()              ((CGFloat)BARandomLongLong()/(CGFloat)LLONG_MAX)
#else
#define BARandomCGFloat                BARandomFloat
#endif
#define BARandomBool()                 (random() & 1)
#define BARandomSignedness()           (BARandomBool() * 2 - 1)
#define BARandomCGFloatInRange(_a, _b) (BARandomCGFloat() * absolute(_b - _a) + MIN(_a,_b))
