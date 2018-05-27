//
//  BABlendedNoise.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 2018-05-27.
//  Copyright © 2018 Bored Astronaut. All rights reserved.
//

#import "BABlendedNoise.h"


@interface BANoiseComponent : NSObject {}
@property (nonatomic, readonly) id<BANoise> noise;
@property (nonatomic) CGFloat contribution;
- (instancetype)initWithNoise:(id<BANoise>)noise contribution:(CGFloat)contribution;
- (BANoiseEvaluator)evaluator;
@end

@implementation BANoiseComponent

- (instancetype)initWithNoise:(id<BANoise>)noise contribution:(CGFloat)contribution {
    self = [super init];
    if (self) {
        _noise = noise;
        _contribution = contribution;
    }
    return self;
}

- (BANoiseEvaluator)evaluator {
    double contribution = _contribution;
    BANoiseEvaluator baseEvaluator = self.noise.evaluator;
    return [^(double x, double y, double z) {
        return baseEvaluator(x, y, z) * contribution;
    } copy];
}

@end


@interface BABlendedNoise()
@property (nonatomic, strong) NSArray<BANoiseComponent *> *components;
@end


@implementation BABlendedNoise

- (NSArray<id<BANoise>> *)noises {
    return [self.components valueForKey:@"noise"];
}

- (NSArray<NSNumber *> *)ratios {
    return [self.components valueForKey:@"component"];
}

- (void)dealloc {
    [_components release];
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
    for (BANoiseComponent *component in self.components) {
        result += [component.noise evaluateX:x Y:y Z:z] * component.contribution;
    }
    return result;
}

- (BANoiseEvaluator)evaluator {
    NSArray<BANoiseEvaluator> *evaluators = [self.components valueForKey:@"evaluator"];
    return [^(double x, double y, double z) {
        double result = 0;
        for (BANoiseEvaluator evaluator in evaluators) {
            result += evaluator(x, y, z);
        }
        return result;
    } copy];
}

- (void)iterateRegion:(BANoiseRegion)region block:(BANoiseIteratorBlock)block increment:(double)inc {
    BANoiseIterate(self.evaluator, block, region, inc);
}

- (instancetype)initWithNoises:(NSArray *)noises ratios:(NSArray *)ratios {
    self = [self init];
    if (self) {
        NSAssert([noises count] == [ratios count], @"Unmatched noise ratios");
    }
    return self;
}

+ (BABlendedNoise *)blendedNoiseWithNoises:(NSArray *)noises ratios:(NSArray *)ratios {
    return [[[self alloc] initWithNoises:noises ratios:ratios] autorelease];
}

@end
