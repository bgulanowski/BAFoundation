//
//  BANoise.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 2013-07-12.
//  Copyright (c) 2013 Lichen Labs. All rights reserved.
//

#import <BAFoundation/BANoise.h>

#import <BAFoundation/BAFunctions.h>
#import <BAFoundation/BANoiseFunctions.h>
#import <BAFoundation/BANoiseTransform.h>

// Implemented in BANoiseFunctions.m
extern void BANoiseInitialize( void );

NS_INLINE void BANoiseDataShuffle(int p[512], NSUInteger seed) {
    
    srandom((unsigned)seed);
    
    for(int i=0; i<256; ++i) {
        int swap = random()&255;
        int temp = p[i];
        p[i]=p[swap];
        p[swap]=temp;
    }
    
    for(int i=0; i<256; ++i)
        p[256+i] = p[i];
}

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
        BANoiseInitialize();
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

#pragma mark - BANoise

- (double)evaluateX:(double)x Y:(double)y Z:(double)z {
    if(_transform) {
        BANoiseVector v = BANoiseVectorMake(x, y, z);
        v = [_transform transformVector:v];
        return BANoiseBlend((int *)[_data bytes], v.x, v.y, v.z, _octaves, _persistence);
    }
    else
        return BANoiseBlend((int *)[_data bytes], x, y, z, _octaves, _persistence);
}

- (void)iterateRegion:(BANoiseRegion)region block:(BANoiseIteratorBlock)block increment:(double)inc {
    BANoiseIterate(self.evaluator, block, region, inc);
}

- (void)iterateRegion:(BANoiseRegion)region block:(BANoiseIteratorBlock)block {
    return [self iterateRegion:region block:block increment:1.0];
}

- (BANoiseEvaluator)evaluator {
	int *bytes = (int *)[_data bytes];
    NSUInteger octaves = _octaves;
    NSUInteger persistence = _persistence;
	if(_transform) {
		BAVectorTransformer transformer = [_transform transformer];
		return [^(double x, double y, double z) {
			BANoiseVector v = transformer(BANoiseVectorMake(x, y, z));
			return BANoiseBlend(bytes, v.x, v.y, v.z, octaves, persistence);
		} copy];
	}
	else {
		return [^(double x, double y, double z) {
			return BANoiseBlend(bytes, x, y, z, octaves, persistence);
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

- (instancetype)initWithSeed:(NSUInteger)seed octaves:(NSUInteger)octaves persistence:(double)persistence transform:(BANoiseTransform *)transform {
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

+ (instancetype)noiseWithSeed:(NSUInteger)seed octaves:(NSUInteger)octaves persistence:(double)persistence transform:(BANoiseTransform *)transform {
    return [[[[self class] alloc] initWithSeed:seed octaves:octaves persistence:persistence transform:transform] autorelease];
}

+ (BANoise *)randomNoise {
    return [[[self alloc] initWithSeed:(NSUInteger)time(NULL)
                               octaves:BARandomIntegerInRange(1, 6)
                           persistence:BARandomCGFloatInRange(0.1, 0.9)
                             transform:[BANoiseTransform randomTransform]] autorelease];
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

- (instancetype)initWithSeed:(NSUInteger)seed octaves:(NSUInteger)octaves persistence:(double)persistence transform:(BANoiseTransform *)transform {
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
			return BASimplexNoise3DBlend(bytes, modulus, x, y, z, _octaves, _persistence);
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

- (void)iterateRegion:(BANoiseRegion)region block:(BANoiseIteratorBlock)block increment:(double)inc {
    BANoiseIterate(self.evaluator, block, region, inc);
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

- (id)initWithSeed:(NSUInteger)seed {
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

+ (NSData *)noiseDataWithSeed:(NSUInteger)seed {
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
    return [[[self alloc] initWithSeed:random()] autorelease];
}

@end


@implementation NSObject (BANoise)

- (NSData *)mapSize2:(BASize2)size min:(double)min max:(double)max {
    
    if(![self conformsToProtocol:@protocol(BANoise)])
        [NSException raise:NSInternalInconsistencyException format:@"Only BANoise adopters can use this method"];
    
    id<BANoise>noise = (id<BANoise>)self;
    size_t alloc_size = sizeof(BOOL) * size.width * size.height;
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

- (id)initWithSize2:(BASize2)initSize noise:(id<BANoise>)noise min:(double)min max:(double)max {
    self = [self initWithSize2:initSize];
    if(self) {
        [self writeBits:(BOOL *)[[(NSObject *)noise mapSize2:initSize min:min max:max] bytes]
                  range:NSMakeRange(0, floor(initSize.height) * floor(initSize.width))];
    }
    return self;
}

+ (BABitArray *)bitArrayWithSize2:(BASize2)size noise:(id<BANoise>)noise min:(double)min max:(double)max {
    return [[[self alloc] initWithSize2:size noise:noise min:min max:max] autorelease];
}

@end
