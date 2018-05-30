//
//  BASimplexNoise.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 2018-05-27.
//  Copyright © 2018 Bored Astronaut. All rights reserved.
//

#import "BASimplexNoise.h"
#import "BANoiseFunctions.h"

@interface BASimplexNoise ()
@property (nonatomic, strong) NSData *mod;
@end

@implementation BASimplexNoise

@synthesize mod=_mod;

- (void)dealloc {
    [_mod release];
    [super dealloc];
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
