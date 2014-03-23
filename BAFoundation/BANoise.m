//
//  BANoise.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 2013-07-12.
//  Copyright (c) 2013 Lichen Labs. All rights reserved.
//

#import <BAFoundation/BANoise.h>


static inline double fade(double t) { return t * t * t * (t * (t * 6 - 15) + 10); }

static inline double lerp(double t, double a, double b) { return a + t * (b - a); }

static inline double grad(int hash, double x, double y, double z) {
	
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

// These are calculated and set in +[BANoise initialize]
static double F2;
static double G2;
static double F3;
static double G3;
static double F4;
static double G4;

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

double BASimplexNoise3DBlend(const int *p, const int *mod, double x, double y, double z, double octave_count, double persistence) {
	
	double result = BASimplexNoise3DEvaluate(p, mod, x, y, z);
	double amplitude = persistence;
    
	for(unsigned i=1; i<octave_count; i++) {
		x *= 2.; y *= 2.; z *= 2.;
		result += BASimplexNoise3DEvaluate(p, mod, x, y, z) * amplitude;
		amplitude *= persistence;
	}
	
	return result;
}

inline static double dot2(BANoiseVector g, double x, double y) {
	return g.x*x + g.y*y;
}

inline static double dot3(BANoiseVector g, double x, double y, double z) {
	return g.x*x + g.y*y + g.z*z;
}

// dot product in 4-space
//inline static double dot(BANoiseVector g, double x, double y, double z, double w) {
//	return g.x*x + g.y*y + g.z*z + g.w*w;
//}


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
	int i = floor(xin+s);
	int j = floor(yin+s);
	int k = floor(zin+s);
	
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
	int ii = i & 255;
	int jj = j & 255;
	int kk = k & 255;
	
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
    200, 196, 135, 130, 116, 188, 159,  86,	164, 100, 109, 198, 173, 186,   3,  64,
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

static inline void BANoiseDataShuffle(int p[512], unsigned seed) {
    
    srandom(seed);
    
    for(int i=0; i<256; ++i) {
        int swap = random()&255;
        int temp = p[i];
        p[i]=p[swap];
        p[swap]=temp;
    }
    
    for(int i=0; i<256; ++i)
        p[256+i] = p[i];
}


inline BANoiseVector BANoiseVectorMake(double x, double y, double z) {
    return (BANoiseVector){ x, y, z };
}

static inline double BANoiseVectorLength(BANoiseVector v) {
    return sqrt(v.x*v.x + v.y*v.y + v.z*v.z);
}

static inline BANoiseVector BANormalizeNoiseVector(BANoiseVector v) {
	
	BANoiseVector r = {};
	double length = BANoiseVectorLength(v);
    
    if(length)
        r.x = v.x/length, r.y = v.y/length, r.z = v.z/length;
	
	return r;
}

static inline void makeIdentityMatrix(double *m) {
    m[ 0] = 1.;
    m[ 1] = 0;
    m[ 2] = 0;
    m[ 3] = 0;
    
    m[ 4] = 0;
    m[ 5] = 1.;
    m[ 6] = 0;
    m[ 7] = 0;
    
    m[ 8] = 0;
    m[ 9] = 0;
    m[10] = 1.;
    m[11] = 0;
    
    m[12] = 0;
    m[13] = 0;
    m[14] = 0;
    m[15] = 1.;
}

static inline void makeScaleMatrix(double m[16], BANoiseVector s) {
    m[ 0] = s.x;
    m[ 1] = 0;
    m[ 2] = 0;
    m[ 3] = 0;
    
    m[ 4] = 0;
    m[ 5] = s.y;
    m[ 6] = 0;
    m[ 7] = 0;
    
    m[ 8] = 0;
    m[ 9] = 0;
    m[10] = s.z;
    m[11] = 0;
    
    m[12] = 0;
    m[13] = 0;
    m[14] = 0;
    m[15] = 1.;
}

static inline void makeLinearTransformationMatrix(double *m, BANoiseVector s, BANoiseVector a, double angle) {

    BANoiseVector nv = BANormalizeNoiseVector(a);
    
	double u = nv.x, v = nv.y, w = nv.z;
	double uu = u*u, vv = v*v, ww = w*w, uv = u*v, uw = u*w, vw = v*w;
	double cosa = cos(angle), ccosa = 1-cosa, sina = sin(angle);
	double usina = u*sina, vsina = v*sina, wsina = w*sina, uvccosa = uv*ccosa, uwccosa = uw*ccosa, vwccosa = vw*ccosa;

    m[ 0] = s.x * (cosa + uu*ccosa);
    m[ 1] =         uvccosa - wsina;
    m[ 2] =         uwccosa + vsina;
    m[ 3] = 0;
    
    m[ 4] =         uvccosa + wsina;
    m[ 5] = s.y * (cosa + vv*ccosa);
    m[ 6] =         vwccosa - usina;
    m[ 7] = 0;
    
    m[ 8] =          uwccosa - vsina;
    m[ 9] =          vwccosa + usina;
    m[10] = s.z * (cosa + ww*ccosa);
    m[11] = 0;
    
    m[12] = 0;
    m[13] = 0;
    m[14] = 0;
    m[15] = 1.;
}

static inline void makeTranslationMatrix(double *m, BANoiseVector t) {
    m[ 0] = 1.;
    m[ 1] = 0;
    m[ 2] = 0;
    m[ 3] = 0;
    
    m[ 4] = 0;
    m[ 5] = 1.;
    m[ 6] = 0;
    m[ 7] = 0;
    
    m[ 8] = 0;
    m[ 9] = 0;
    m[10] = 1.;
    m[11] = 0;
    
    m[12] = t.x;
    m[13] = t.y;
    m[14] = t.z;
    m[15] = 1.;
}

static inline BOOL equalMatrices(double m1[16], double m2[16]) {
    for (NSUInteger i=0; i<16; ++i)
        if(m1[i] != m2[i]) return NO;
    return YES;
}

static BANoiseVector transformVector(BANoiseVector vector, double *matrix) {
    
    BANoiseVector r;
    
    r.x = vector.x * matrix[0] + vector.y * matrix[4] + vector.z * matrix[8];
    r.y = vector.x * matrix[1] + vector.y * matrix[5] + vector.z * matrix[9];
    r.z = vector.x * matrix[2] + vector.y * matrix[6] + vector.z * matrix[10];
    
    return r;
}


@implementation BANoiseTransform

@synthesize scale=_scale, rotationAxis=_rotationAxis, rotationAngle=_rotationAngle, translation=_translation;

- (double *)matrix {
    return _matrix;
}

- (BOOL)isEqualToTransform:(BANoiseTransform *)transform {
    return equalMatrices(_matrix, transform->_matrix);
}

- (id)initWithMatrix:(double *)matrix {
    self = [self init];
    if(self) {
        for (NSUInteger i=0; i<16; ++i)
            _matrix[i] = matrix[i];
    }
    return self;
}

- (id)initWithScale:(BANoiseVector)scale rotationAxis:(BANoiseVector)axis angle:(double)angle {
    double m[16];
    makeLinearTransformationMatrix(m, scale, axis, angle);
    self = [self initWithMatrix:m];
    if(self) {
        _scale = scale;
        _rotationAxis = axis;
        _rotationAngle = angle;
    }
    return self;
}

- (id)initWithScale:(BANoiseVector)scale {
    double m[16];
    makeScaleMatrix(m, scale);
    self = [self initWithMatrix:m];
    if(self) {
        _scale = scale;
    }
    return self;
}

- (id)initWithRotationAxis:(BANoiseVector)axis angle:(double)angle {
    return [self initWithScale:BANoiseVectorMake(1., 1., 1.) rotationAxis:axis angle:angle];
}

- (id)initWithTranslation:(BANoiseVector)translation {
    double m[16];
    makeTranslationMatrix(m, translation);
    self = [self initWithMatrix:m];
    if(self) {
        _translation = translation;
    }
    return self;
}

- (BANoiseTransform *)transformByPremultiplyingTransform:(BANoiseTransform *)transform {
    
    double r[16];
    double *t = transform->_matrix;
    double *m = _matrix;
    
    r[ 0] = t[ 0] * m[ 0] + t[ 4] * m[ 1] + t[ 8] * m[ 2] + t[12] * m[ 3];
    r[ 1] = t[ 1] * m[ 0] + t[ 5] * m[ 1] + t[ 9] * m[ 2] + t[13] * m[ 3];
    r[ 2] = t[ 2] * m[ 0] + t[ 6] * m[ 1] + t[10] * m[ 2] + t[14] * m[ 3];
    r[ 3] = t[ 3] * m[ 0] + t[ 7] * m[ 1] + t[11] * m[ 2] + t[15] * m[ 3];
    
    r[ 4] = t[ 0] * m[ 4] + t[ 4] * m[ 5] + t[ 8] * m[ 6] + t[12] * m[ 7];
    r[ 5] = t[ 1] * m[ 4] + t[ 5] * m[ 5] + t[ 9] * m[ 6] + t[13] * m[ 7];
    r[ 6] = t[ 2] * m[ 4] + t[ 6] * m[ 5] + t[10] * m[ 6] + t[14] * m[ 7];
    r[ 7] = t[ 3] * m[ 4] + t[ 7] * m[ 5] + t[11] * m[ 6] + t[15] * m[ 7];
    
    r[ 8] = t[ 0] * m[ 8] + t[ 4] * m[ 9] + t[ 8] * m[10] + t[12] * m[11];
    r[ 9] = t[ 1] * m[ 8] + t[ 5] * m[ 9] + t[ 9] * m[10] + t[13] * m[11];
    r[10] = t[ 2] * m[ 8] + t[ 6] * m[ 9] + t[10] * m[10] + t[14] * m[11];
    r[11] = t[ 3] * m[ 8] + t[ 7] * m[ 9] + t[11] * m[10] + t[15] * m[11];
    
    r[12] = t[ 0] * m[12] + t[ 4] * m[13] + t[ 8] * m[14] + t[12] * m[15];
    r[13] = t[ 1] * m[12] + t[ 5] * m[13] + t[ 9] * m[14] + t[13] * m[15];
    r[14] = t[ 2] * m[12] + t[ 6] * m[13] + t[10] * m[14] + t[14] * m[15];
    r[15] = t[ 3] * m[12] + t[ 7] * m[13] + t[11] * m[14] + t[15] * m[15];
    
    return [[[[self class] alloc] initWithMatrix:r] autorelease];
}

- (BANoiseVector)transformVector:(BANoiseVector)vector {
    return transformVector(vector, _matrix);
}

- (BAVectorTransformer)transformer {
	return [^(BANoiseVector vector) { return transformVector(vector, _matrix); } copy];
}

@end


@interface BANoise ()
@property (nonatomic, strong) NSData *data;
@end


@implementation BANoise

@synthesize seed=_seed, octaves=_octaves, persistence=_persistence, transform=_transform, data=_data;

#pragma mark - NSObject

- (void)dealloc {
    [_transform release], _transform = nil;
    [_data release], _data = nil;
    [super dealloc];
}

- (NSUInteger)hash {
    return _seed;
}

- (id)init {
	return [self initWithSeed:0 octaves:1 persistence:0 transform:nil];
}

+ (void)initialize {
	if (self == [BANoise class]) {
		F2 = 0.5*(sqrt(3.0)-1.0);
		G2 = (3.0-sqrt(3.0))/6.0;
		F3 = 1.0/3.0;
		G3 = 1.0/6.0;
		F4 = (sqrt(5.0)-1.0)/4.0;
		G4 = (5.0-sqrt(5.0))/20.0;
	}
}


#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if(self) {
        _transform = [[aDecoder decodeObjectForKey:@"transform"] retain];
        _data = [[aDecoder decodeObjectForKey:@"data"] retain];
        _seed = [aDecoder decodeIntegerForKey:@"seed"];
        _octaves = [aDecoder decodeIntegerForKey:@"octaves"];
        _persistence = [aDecoder decodeDoubleForKey:@"persistence"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    if(_transform)
        [aCoder encodeObject:_transform forKey:@"transform"];
    [aCoder encodeObject:_data forKey:@"data"];
    [aCoder encodeInteger:(NSInteger)_seed forKey:@"seed"];
    [aCoder encodeInteger:(NSInteger)_octaves forKey:@"octaves"];
    [aCoder encodeDouble:_persistence forKey:@"persistence"];
}


#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {

    BANoise *copy = [[[self class] alloc] init];
    
    copy->_transform = [_transform retain];
    copy->_data = [_data retain];
    copy->_seed = _seed;
    copy->_octaves = _octaves;
    copy->_persistence = _persistence;
    
    return copy;
}

#pragma mark - BANoise protocol

- (double)evaluateX:(double)x Y:(double)y Z:(double)z {
    if(_transform) {
        BANoiseVector v = BANoiseVectorMake(x, y, z);
        v = [_transform transformVector:v];
        return BANoiseBlend((int *)[_data bytes], v.x, v.y, v.z, _octaves, _persistence);
    }
    else
        return BANoiseBlend((int *)[_data bytes], x, y, z, _octaves, _persistence);
}

- (void)iterateRange:(BANoiseRegion)range block:(BANoiseIteratorBlock)block {
    
    double maxX = range.origin.x + range.size.x;
    double maxY = range.origin.y + range.size.y;
    double maxZ = range.origin.z + range.size.z;
    
    int *p = (int *)[_data bytes];
    double *m = [_transform matrix];
    
    for (double z = range.origin.z; z < maxZ; ++z) {
        for (double y = range.origin.y; y < maxY; ++y) {
            for (double x = range.origin.z; x < maxX; ++x) {
                BANoiseVector v = transformVector(BANoiseVectorMake(x, y, z), m);
                if(block(v, BANoiseBlend(p, v.x, v.y, v.z, _octaves, _persistence)))
                    return;
            }
        }
    }
}


#pragma mark - BANoise

- (BANoiseEvaluator)evaluator {
	int *bytes = (int *)[_data bytes];
	if(_transform) {
		BAVectorTransformer transformer = [_transform transformer];
		return [^(double x, double y, double z) {
			BANoiseVector v = transformer(BANoiseVectorMake(x, y, z));
			return BANoiseBlend(bytes, v.x, v.y, v.z, _octaves, _persistence);
		} copy];
	}
	else {
		return [^(double x, double y, double z) {
			return BANoiseBlend(bytes, x, y, z, _octaves, _persistence);
		} copy];
	}
}

- (BOOL)isEqualToNoise:(BANoise *)other {
    return other->_seed == _seed && other->_octaves == _octaves && other->_persistence == _persistence && [other->_data isEqualToData:_data];
}

- (BANoise *)copyWithOctaves:(NSUInteger)octaves persistence:(double)persistence transform:(BANoiseTransform *)transform {
    
    BANoise *copy = [self copyWithZone:[self zone]];
    
    copy->_transform = [transform retain];
    copy->_octaves = octaves;
    copy->_persistence = persistence;
    
    return copy;
}

- (instancetype)initWithSeed:(unsigned)seed octaves:(NSUInteger)octaves persistence:(double)persistence transform:(BANoiseTransform *)transform {
    self = [super init];
    if(self) {
        _seed = seed;
        _octaves = octaves;
        _persistence = persistence;
        _transform = [transform retain];
        self.data = [NSData noiseDataWithSeed:seed];
    }
    return self;
}

+ (instancetype)noiseWithSeed:(unsigned)seed octaves:(NSUInteger)octaves persistence:(double)persistence transform:(BANoiseTransform *)transform {
    return [[[[self class] alloc] initWithSeed:seed octaves:octaves persistence:persistence transform:transform] autorelease];
}

@end


@interface BASimplexNoise ()
@property (nonatomic, strong) NSData *mod;
@end


@implementation BASimplexNoise

@synthesize mod=_mod;

- (void)dealloc {
	[super dealloc];
	[_mod release];
}

- (instancetype)initWithSeed:(unsigned)seed octaves:(NSUInteger)octaves persistence:(double)persistence transform:(BANoiseTransform *)transform {
	self = [super initWithSeed:seed octaves:octaves persistence:persistence transform:transform];
	if (self) {
		self.mod = [_data noiseModulusData];
	}
	return self;
}

- (double)evaluateX:(double)x Y:(double)y {
	return BASimplexNoise3DBlend([_data bytes], [_mod bytes], x, y, 0, _octaves, _persistence);
}

- (double)evaluateX:(double)x Y:(double)y Z:(double)z {
	return BASimplexNoise3DBlend([_data bytes], [_mod bytes], x, y, z, _octaves, _persistence);
}

- (BANoiseEvaluator)evaluator {
	int *bytes = (int *)[_data bytes];
	int *modulus = (int *)[_mod bytes];
	if(_transform) {
		BAVectorTransformer transformer = [_transform transformer];
		return [^(double x, double y, double z) {
			BANoiseVector v = transformer(BANoiseVectorMake(x, y, z));
			return BASimplexNoise3DBlend(bytes, modulus, v.x, v.y, v.z, _octaves, _persistence);
		} copy];
	}
	else {
		return [^(double x, double y, double z) {
			return BASimplexNoise3DEvaluate(bytes, modulus, x, y, z);
		} copy];
	}
}

@end


@implementation BABlendedNoise

@synthesize noises=_noises;
@synthesize ratios=_ratios;

- (void)dealloc {
	[_noises release], _noises = nil;
	[_ratios release], _ratios = nil;
	[super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (double)evaluateX:(double)x Y:(double)y Z:(double)z {
    
    double result = 0;
	NSUInteger index = 0;
	for (id<BANoise> noise in _noises) {
		double ratio = [[_ratios objectAtIndex:index++] doubleValue];
        result += [noise evaluateX:x Y:y Z:z] * ratio;
    }
    
    return result;
}

- (instancetype)initWithNoises:(NSArray *)noises ratios:(NSArray *)ratios {
	self = [self init];
	if (self) {
		NSAssert([noises count] == [ratios count], @"Unmatched noise ratios");
		_count = [noises count];
		_noises = [noises copy];
		_ratios = [ratios copy];
	}
	return self;
}

+ (BABlendedNoise *)blendedNoiseWithNoises:(NSArray *)noises ratios:(NSArray *)ratios {
	return [[[self alloc] initWithNoises:noises ratios:ratios] autorelease];
}

@end


@implementation NSData (BANoise)

- (id)initWithSeed:(unsigned)seed {
    int p[512];
    for(int i=0; i<256; i++) p[i]=i;
    BANoiseDataShuffle(p, seed);
    return [self initWithBytes:p length:512*sizeof(int)];
}

- (NSData *)noiseModulusData {
	int m[512];
	const int *p = [self bytes];
	for (NSUInteger i=0; i<512; ++i) {
		m[i] = p[i]%12;
	}
	return [NSData dataWithBytes:m length:512*sizeof(int)];
}

+ (NSData *)noiseDataWithSeed:(unsigned)seed {
	if (seed == 0) {
		return [self defaultNoiseData];
	}
    return [[[self alloc] initWithSeed:seed] autorelease];
}

+ (NSData *)defaultNoiseData {
    return [[[self alloc] initWithBytes:BADefaultPermutation length:512*sizeof(int)] autorelease];
}

+ (NSData *)randomNoiseData {
    srandom((unsigned)time(NULL));
    return [[[self alloc] initWithSeed:(unsigned)random()] autorelease];
}

@end


@implementation NSObject (BANoise)

- (NSData *)mapSize:(CGSize)size min:(double)min max:(double)max {
    
    if(![self conformsToProtocol:@protocol(BANoise)])
        [NSException raise:NSInternalInconsistencyException format:@"Only BANoise adopters can use this method"];
    
    id<BANoise>noise = (id<BANoise>)self;
    size_t alloc_size = sizeof(BOOL)*floor(size.width)*floor(size.height);
    BOOL *map = malloc(alloc_size);
    
    if(!map)
        exit(1);
    
    NSUInteger index = 0;
    
    for (double j=0; j<size.height; ++j) {
        for (double i=0; i<size.width; ++i) {
            double val = [noise evaluateX:i Y:j Z:0];
            map[index++] = val >= min && val <= max;
        }
    }
    
    return [NSData dataWithBytesNoCopy:map length:alloc_size freeWhenDone:YES];
}

@end


@implementation BABitArray (BANoiseInitializing)

- (id)initWithSize:(CGSize)initSize noise:(id<BANoise>)noise min:(double)min max:(double)max {
    self = [self initWithSize:initSize];
    if(self) {
        [self writeBits:(BOOL *)[[(NSObject *)noise mapSize:initSize min:min max:max] bytes]
                  range:NSMakeRange(0, floor(initSize.height) * floor(initSize.width))];
    }
    return self;
}

+ (BABitArray *)bitArrayWithSize:(CGSize)size noise:(id<BANoise>)noise min:(double)min max:(double)max {
    return [[[self alloc] initWithSize:size noise:noise min:min max:max] autorelease];
}

@end
