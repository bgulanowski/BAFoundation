//
//  BABlendedNoise.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 2018-05-27.
//  Copyright © 2018 Bored Astronaut. All rights reserved.
//

#import "BABlendedNoise.h"


@interface BANoiseComponent : NSObject<BANoise> {}
@property (nonatomic, readonly) id<BANoise> noise;
@property (nonatomic) CGFloat contribution;
- (instancetype)initWithNoise:(id<BANoise>)noise contribution:(CGFloat)contribution;
@end

@implementation BANoiseComponent

#pragma mark - NSObject

- (void)dealloc {
    [_noise release];
    [super dealloc];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSKeyedUnarchiver *)aDecoder {
    return [self initWithNoise:[aDecoder decodeObjectForKey:NSStringFromSelector(@selector(noise))]
                  contribution:[aDecoder decodeDoubleForKey:NSStringFromSelector(@selector(contribution))]];
}

- (void)encodeWithCoder:(NSKeyedArchiver *)aCoder {
    [aCoder encodeObject:self.noise forKey:NSStringFromSelector(@selector(noise))];
    [aCoder encodeDouble:self.contribution forKey:NSStringFromSelector(@selector(contribution))];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    return [[BANoiseComponent alloc] initWithNoise:[self.noise copyWithZone:zone] contribution:self.contribution];
}

#pragma mark - BANoise

- (double)evaluateX:(double)x Y:(double)y Z:(double)z {
    return [self.noise evaluateX:x Y:y Z:z] * self.contribution;
}

- (BANoiseEvaluator)evaluator {
    double contribution = _contribution;
    BANoiseEvaluator baseEvaluator = self.noise.evaluator;
    return [^(double x, double y, double z) {
        return baseEvaluator(x, y, z) * contribution;
    } copy];
}

#pragma mark - BANoiseComponent

- (instancetype)initWithNoise:(id<BANoise>)noise contribution:(CGFloat)contribution {
    self = [super init];
    if (self) {
        _noise = noise;
        _contribution = contribution;
    }
    return self;
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

- (id)initWithCoder:(NSKeyedUnarchiver *)aDecoder {
    return [self initWithComponents:[aDecoder decodeObjectForKey:NSStringFromSelector(@selector(components))]];
}

- (void)encodeWithCoder:(NSKeyedArchiver *)aCoder {
    [aCoder encodeObject:self.components forKey:NSStringFromSelector(@selector(components))];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (double)evaluateX:(double)x Y:(double)y Z:(double)z {
    double result = 0;
    for (BANoiseComponent *component in self.components) {
        result += [component.noise evaluateX:x Y:y Z:z] * component.contribution;
    }
    return result / self.components.count;
}

- (BANoiseEvaluator)evaluator {
    NSArray<BANoiseEvaluator> *evaluators = [self.components valueForKey:@"evaluator"];
    return [^(double x, double y, double z) {
        double result = 0;
        for (BANoiseEvaluator evaluator in evaluators) {
            result += evaluator(x, y, z);
        }
        return result/evaluators.count;
    } copy];
}

- (void)iterateRegion:(BANoiseRegion)region block:(BANoiseIteratorBlock)block increment:(double)inc {
    BANoiseIterate(self.evaluator, block, region, inc);
}

- (instancetype)initWithComponents:(NSArray<BANoiseComponent *> *)components {
    self = [self init];
    if (self) {
        self.components = [[components copy] autorelease];
    }
    return self;
}

- (instancetype)initWithNoises:(NSArray<id<BANoise>> *)noises ratios:(NSArray<NSNumber *> *)ratios {
    NSEnumerator<NSNumber *> *ratiosEnumerator = [ratios objectEnumerator];
    NSMutableArray<BANoiseComponent *> *components = [NSMutableArray<BANoiseComponent *> array];
    for (id<BANoise> noise in noises) {
        [components addObject:[[[BANoiseComponent alloc] initWithNoise:noise contribution:[[ratiosEnumerator nextObject] doubleValue]] autorelease]];
    }
    return [self initWithComponents:components];
}

+ (BABlendedNoise *)blendedNoiseWithNoises:(NSArray *)noises ratios:(NSArray *)ratios {
    return [[[self alloc] initWithNoises:noises ratios:ratios] autorelease];
}

@end
