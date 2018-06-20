//
//  BANoiseFunctions.c
//  BAFoundation
//
//  Created by Brent Gulanowski on 2018-05-16.
//  Copyright © 2018 Lichen Labs. All rights reserved.
//

#import "BANoiseFunctions.h"

// To quiet compiler
void BANoiseInitialize( void );

NS_INLINE double fade(double t) { return t * t * t * (t * (t * 6 - 15) + 10); }

NS_INLINE double lerp(double t, double a, double b) { return a + t * (b - a); }

NS_INLINE double grad(int hash, double x, double y, double z) {
    
    int h = hash & 15;
    double u = h < 8 ? x : y;
    double v = h < 4 ? y : h==12||h==14 ? x : z;
    
    return ((h&1) == 0 ? u : -u) + ((h&2) == 0 ? v : -v);
}

double BANoiseEvaluate(const int *p, double x, double y, double z) {
    
    int X; int Y; int Z;
    double u; double v; double w;
    
    int A; int AA; int AB;
    double gAA0; double gAA1; double gAB0; double gAB1;
    
    int B; int BA; int BB;
    double gBA0; double gBA1; double gBB0; double gBB1;
    
    double lerp1; double lerp2; double lerp3; double lerp4; double lerp5; double lerp6; double lerp7;
    
    X = (int)floor(x) & 255; Y = (int)floor(y) & 255; Z = (int)floor(z) & 255;
    
    x -= floor(x); y -= floor(y); z -= floor(z);
    
    u = fade(x); v = fade(y); w = fade(z);
    
    A  = p[X  ]+Y; AA = p[A  ]+Z; AB = p[A+1]+Z;
    
    gAA0 = grad(p[AA  ],   x,   y,   z);
    gAA1 = grad(p[AA+1],   x,   y, z-1);
    gAB0 = grad(p[AB  ],   x, y-1,   z);
    gAB1 = grad(p[AB+1],   x, y-1, z-1);
    
    B  = p[X+1]+Y;
    BA = p[B  ]+Z;
    BB = p[B+1]+Z;
    
    gBA0 = grad(p[BA  ], x-1,   y,   z);
    gBA1 = grad(p[BA+1], x-1,   y, z-1);
    gBB0 = grad(p[BB  ], x-1, y-1,   z);
    gBB1 = grad(p[BB+1], x-1, y-1, z-1);
    
    lerp1 = lerp( u, gAA0, gBA0);
    lerp2 = lerp( u, gAA1, gBA1);
    
    lerp3 = lerp( u, gAB0, gBB0);
    lerp4 = lerp( u, gAB1, gBB1);
    
    lerp5 = lerp( v, lerp1, lerp3);
    lerp6 = lerp( v, lerp2, lerp4);
    
    lerp7 = lerp( w, lerp5, lerp6);
    
    return lerp7;
}

const BANoiseVector grad3[] = {
    { 1, 1, 0}, {-1, 1, 0}, { 1,-1, 0}, {-1,-1, 0},
    { 1, 0, 1}, {-1, 0, 1}, { 1, 0,-1}, {-1, 0,-1},
    { 0, 1, 1}, { 0,-1, 1}, { 0, 1,-1}, { 0,-1,-1}
};

static double F2;
static double G2;
static double F3;
static double G3;
static double F4;
static double G4;

// Called by +[BANoise initialize]
void BANoiseInitialize( void ) {
    F2 = 0.5*(sqrt(3.0)-1.0);
    G2 = (3.0-sqrt(3.0))/6.0;
    F3 = 1.0/3.0;
    G3 = 1.0/6.0;
    F4 = (sqrt(5.0)-1.0)/4.0;
    G4 = (5.0-sqrt(5.0))/20.0;
}

double BANoiseBlend(const int *p, double x, double y, double z, double octave_count, double persistence) {
    
    double result = BANoiseEvaluate(p, x, y, z);
    double amplitude = persistence;
    
    for(unsigned i=1; i<octave_count; i++) {
        x *= 2.; y *= 2.; z *= 2.;
        result += BANoiseEvaluate(p, x, y, z) * amplitude;
        amplitude *= persistence;
    }
    
    return result;
}

#pragma mar - Helpers

inline static double dot2(BANoiseVector g, double x, double y) {
    return g.x*x + g.y*y;
}

inline static double dot3(BANoiseVector g, double x, double y, double z) {
    return g.x*x + g.y*y + g.z*z;
}

// dot product in 4-space
//inline static double dot(BANoiseVector g, double x, double y, double z, double w) {
//    return g.x*x + g.y*y + g.z*z + g.w*w;
//}

#pragma mark - Simplex Noise

double BASimplexNoise2DEvaluate(const int *p, const int *pmod, double xin, double  yin) {
    
    // Noise contributions from the three corners
    double n0, n1, n2;
    
    // Skew the input space to determine which simplex cell we're in
    // Hairy factor for 2D
    double s = (xin+yin)*F2;
    int i = floor(xin+s);
    int j = floor(yin+s);
    
    double t = (i+j)*G2;
    
    // Unskew the cell origin back to (x,y) space
    double X0 = i-t;
    double Y0 = j-t;
    
    // The x,y distances from the cell origin
    double x0 = xin-X0;
    double y0 = yin-Y0;
    
    // For the 2D case, the simplex shape is an equilateral triangle.
    // Determine which simplex we are in.
    int i1, j1; // Offsets for second (middle) corner of simplex in (i,j) coords
    
    if(x0>y0) {
        // lower triangle, XY order: (0,0)->(1,0)->(1,1)
        i1=1; j1=0;
    }
    else {
        // upper triangle, YX order: (0,0)->(0,1)->(1,1)
        i1=0; j1=1;
    }
    // A step of (1,0) in (i,j) means a step of (1-c,-c) in (x,y), and
    // a step of (0,1) in (i,j) means a step of (-c,1-c) in (x,y), where
    // c = (3-sqrt(3))/6
    double x1 = x0 - i1 + G2; // Offsets for middle corner in (x,y) unskewed coords
    double y1 = y0 - j1 + G2;
    double x2 = x0 - 1.0 + 2.0 * G2; // Offsets for last corner in (x,y) unskewed coords
    double y2 = y0 - 1.0 + 2.0 * G2;
    // Work out the hashed gradient indices of the three simplex corners
    int ii = i & 255;
    int jj = j & 255;
    int gi0 = pmod[ii+p[jj]];
    int gi1 = pmod[ii+i1+p[jj+j1]];
    int gi2 = pmod[ii+1+p[jj+1]];
    
    // Calculate the contribution from the three corners
    double t0 = 0.5 - x0*x0-y0*y0;
    if(t0<0) n0 = 0.0;
    else {
        t0 *= t0;
        n0 = t0 * t0 * dot2(grad3[gi0], x0, y0);  // (x,y) of grad3 used for 2D gradient
    }
    double t1 = 0.5 - x1*x1-y1*y1;
    if(t1<0) n1 = 0.0;
    else {
        t1 *= t1;
        n1 = t1 * t1 * dot2(grad3[gi1], x1, y1);
    }
    double t2 = 0.5 - x2*x2-y2*y2;
    if(t2<0) n2 = 0.0;
    else {
        t2 *= t2;
        n2 = t2 * t2 * dot2(grad3[gi2], x2, y2);
    }
    // Add contributions from each corner to get the final noise value.
    // The result is scaled to return values in the interval [-1,1].
    return 70.0 * (n0 + n1 + n2);
}

double BASimplexNoise3DEvaluate(const int *p, const int *pmod, double xin, double  yin, double zin) {
    
    // Noise contributions from the four corners
    double n0, n1, n2, n3;
    
    // Skew the input space to determine which simplex cell we're in
    // Very nice and simple skew factor for 3D
    double s = (xin+yin+zin)*F3;
    double i = floor(xin+s);
    double j = floor(yin+s);
    double k = floor(zin+s);
    
    double t = (i+j+k)*G3;
    // Unskew the cell origin back to (x,y,z) space
    double X0 = i-t;
    double Y0 = j-t;
    double Z0 = k-t;
    
    // The x,y,z distances from the cell origin
    double x0 = xin-X0;
    double y0 = yin-Y0;
    double z0 = zin-Z0;
    
    // For the 3D case, the simplex shape is a slightly irregular tetrahedron.
    // Determine which simplex we are in.
    int i1, j1, k1; // Offsets for second corner of simplex in (i,j,k) coords
    int i2, j2, k2; // Offsets for third corner of simplex in (i,j,k) coords
    if(x0>=y0) {
        if(y0>=z0) {
            // X Y Z order
            i1=1; j1=0; k1=0; i2=1; j2=1; k2=0;
        }
        else if(x0>=z0) {
            // X Z Y order
            i1=1; j1=0; k1=0; i2=1; j2=0; k2=1;
        }
        else {
            // Z X Y order
            i1=0; j1=0; k1=1; i2=1; j2=0; k2=1; }
    }
    else {
        // x0<y0
        if(y0<z0) {
            // Z Y X order
            i1=0; j1=0; k1=1; i2=0; j2=1; k2=1;
        }
        else if(x0<z0) {
            // Y Z X order
            i1=0; j1=1; k1=0; i2=0; j2=1; k2=1;
        }
        else {
            // Y X Z order
            i1=0; j1=1; k1=0; i2=1; j2=1; k2=0;
        }
    }
    
    // A step of (1,0,0) in (i,j,k) means a step of (1-c,-c,-c) in (x,y,z),
    // a step of (0,1,0) in (i,j,k) means a step of (-c,1-c,-c) in (x,y,z), and
    // a step of (0,0,1) in (i,j,k) means a step of (-c,-c,1-c) in (x,y,z), where
    // c = 1/6.
    double x1 = x0 - i1 + G3; // Offsets for second corner in (x,y,z) coords
    double y1 = y0 - j1 + G3;
    double z1 = z0 - k1 + G3;
    double x2 = x0 - i2 + 2.0*G3; // Offsets for third corner in (x,y,z) coords
    double y2 = y0 - j2 + 2.0*G3;
    double z2 = z0 - k2 + 2.0*G3;
    double x3 = x0 - 1.0 + 3.0*G3; // Offsets for last corner in (x,y,z) coords
    double y3 = y0 - 1.0 + 3.0*G3;
    double z3 = z0 - 1.0 + 3.0*G3;
    
    // Work out the hashed gradient indices of the four simplex corners
    int ii = (int)i & 255;
    int jj = (int)j & 255;
    int kk = (int)k & 255;
    
    int gi0 = pmod[ii+p[jj+p[kk]]];
    int gi1 = pmod[ii+i1+p[jj+j1+p[kk+k1]]];
    int gi2 = pmod[ii+i2+p[jj+j2+p[kk+k2]]];
    int gi3 = pmod[ii+1+p[jj+1+p[kk+1]]];
    
    // Calculate the contribution from the four corners
    double t0 = 0.6 - x0*x0 - y0*y0 - z0*z0;
    if(t0<0) {
        n0 = 0.0;
    }
    else {
        t0 *= t0;
        n0 = t0 * t0 * dot3(grad3[gi0], x0, y0, z0);
    }
    
    double t1 = 0.6 - x1*x1 - y1*y1 - z1*z1;
    if(t1<0) {
        n1 = 0.0;
    }
    else {
        t1 *= t1;
        n1 = t1 * t1 * dot3(grad3[gi1], x1, y1, z1);
    }
    
    double t2 = 0.6 - x2*x2 - y2*y2 - z2*z2;
    if(t2<0) {
        n2 = 0.0;
    }
    else {
        t2 *= t2;
        n2 = t2 * t2 * dot3(grad3[gi2], x2, y2, z2);
    }
    
    double t3 = 0.6 - x3*x3 - y3*y3 - z3*z3;
    if(t3<0) {
        n3 = 0.0;
    }
    else {
        t3 *= t3;
        n3 = t3 * t3 * dot3(grad3[gi3], x3, y3, z3);
    }
    
    // Add contributions from each corner to get the final noise value.
    // The result is scaled to stay just inside [-1,1]
    return 32.0 * (n0 + n1 + n2 + n3);
}


const int BADefaultPermutation[512] = {
    151, 160, 137,  91,  90,  15, 131,  13, 201,  95,  96,  53, 194, 233,   7, 225,
    140,  36, 103,  30,  69, 142,   8,  99,  37, 240,  21,  10,  23, 190,   6, 148,
    247, 120, 234,  75,   0,  26, 197,  62,  94, 252, 219, 203, 117,  35,  11,  32,
     57, 177,  33,  88, 237, 149,  56,  87, 174,  20, 125, 136, 171, 168,  68, 175,
     74, 165,  71, 134, 139,  48,  27, 166,  77, 146, 158, 231,  83, 111, 229, 122,
     60, 211, 133, 230, 220, 105,  92,  41,  55,  46, 245,  40, 244, 102, 143,  54,
     65,  25,  63, 161,   1, 216,  80,  73, 209,  76, 132, 187, 208,  89,  18, 169,
    200, 196, 135, 130, 116, 188, 159,  86, 164, 100, 109, 198, 173, 186,   3,  64,
     52, 217, 226, 250, 124, 123,   5, 202,  38, 147, 118, 126, 255,  82,  85, 212,
    207, 206,  59, 227,  47,  16,  58,  17, 182, 189,  28,  42, 223, 183, 170, 213,
    119, 248, 152,   2,  44, 154, 163,  70, 221, 153, 101, 155, 167,  43, 172,   9,
    129,  22,  39, 253,  19,  98, 108, 110,  79, 113, 224, 232, 178, 185, 112, 104,
    218, 246,  97, 228, 251,  34, 242, 193, 238, 210, 144,  12, 191, 179, 162, 241,
     81,  51, 145, 235, 249,  14, 239, 107,  49, 192, 214,  31, 181, 199, 106, 157,
    184,  84, 204, 176, 115, 121,  50,  45, 127,   4, 150, 254, 138, 236, 205,  93,
    222, 114,  67,  29,  24,  72, 243, 141, 128, 195,  78,  66, 215,  61, 156, 180,
    // repeat
    151, 160, 137,  91,  90,  15, 131,  13, 201,  95,  96,  53, 194, 233,   7, 225,
    140,  36, 103,  30,  69, 142,   8,  99,  37, 240,  21,  10,  23, 190,   6, 148,
    247, 120, 234,  75,   0,  26, 197,  62,  94, 252, 219, 203, 117,  35,  11,  32,
     57, 177,  33,  88, 237, 149,  56,  87, 174,  20, 125, 136, 171, 168,  68, 175,
     74, 165,  71, 134, 139,  48,  27, 166,  77, 146, 158, 231,  83, 111, 229, 122,
     60, 211, 133, 230, 220, 105,  92,  41,  55,  46, 245,  40, 244, 102, 143,  54,
     65,  25,  63, 161,   1, 216,  80,  73, 209,  76, 132, 187, 208,  89,  18, 169,
    200, 196, 135, 130, 116, 188, 159,  86, 164, 100, 109, 198, 173, 186,   3,  64,
     52, 217, 226, 250, 124, 123,   5, 202,  38, 147, 118, 126, 255,  82,  85, 212,
    207, 206,  59, 227,  47,  16,  58,  17, 182, 189,  28,  42, 223, 183, 170, 213,
    119, 248, 152,   2,  44, 154, 163,  70, 221, 153, 101, 155, 167,  43, 172,   9,
    129,  22,  39, 253,  19,  98, 108, 110,  79, 113, 224, 232, 178, 185, 112, 104,
    218, 246,  97, 228, 251,  34, 242, 193, 238, 210, 144,  12, 191, 179, 162, 241,
     81,  51, 145, 235, 249,  14, 239, 107,  49, 192, 214,  31, 181, 199, 106, 157,
    184,  84, 204, 176, 115, 121,  50,  45, 127,   4, 150, 254, 138, 236, 205,  93,
    222, 114,  67,  29,  24,  72, 243, 141, 128, 195,  78,  66, 215,  61, 156, 180
};

static double BASimplexNoise3DBlendInternal(const int *p, const int *mod, double x, double y, double z, double octave_count, double persistence, double (*function)(const int *p, const int *pmod, double xin, double  yin, double zin)) {
    
    double result = function(p, mod, x, y, z);
    double amplitude = persistence;
    
    for(unsigned i=1; i<octave_count; i++) {
        x *= 2.; y *= 2.; z *= 2.;
        result += function(p, mod, x, y, z) * amplitude;
        amplitude *= persistence;
    }
    
    return result;
}

double BASimplexNoise3DBlend(const int *p, const int *mod, double x, double y, double z, double octave_count, double persistence) {
    return BASimplexNoise3DBlendInternal(p, mod, x, y, z, octave_count, persistence, BASimplexNoise3DEvaluate);
}

inline static double Identity(const int *p, const int *pmod, double xin, double  yin, double zin) {
    return 1.0f;
}

double BASimplexNoiseMax(double octave_count, double persistence) {
    return BASimplexNoise3DBlendInternal(NULL, NULL, 0, 0, 0, octave_count, persistence, Identity);
}

#pragma mark - Utilities

void BANoiseIterate(BANoiseEvaluator evaluator, BANoiseIteratorBlock block, BANoiseRegion region, double inc) {
    
    double maxX = region.origin.x + region.size.x;
    double maxY = region.origin.y + region.size.y;
    double maxZ = region.origin.z + region.size.z;
    
    for (double z = region.origin.z; z < maxZ; z += inc) {
        for (double y = region.origin.y; y < maxY; y += inc) {
            for (double x = region.origin.x; x < maxX; x += inc) {
                double ix = x*inc, iy = y*inc, iz = z*inc;
                if(block(ix, iy, iz, evaluator(ix, iy, iz)))
                    return;
            }
        }
    }
}

@implementation NSValue (BANoiseVector)
+ (instancetype)valueWithNoiseVector:(BANoiseVector)v {
    return [self valueWithBytes:&v objCType:@encode(BANoiseVector)];
}

- (BANoiseVector)noiseVector {
    BANoiseVector v;
    [self getValue:&v];
    return v;
}
@end
