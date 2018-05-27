//
//  BABlendedNoise.h
//  BAFoundation
//
//  Created by Brent Gulanowski on 2018-05-27.
//  Copyright © 2018 Bored Astronaut. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BAFoundation/BAFoundation.h>

@interface BABlendedNoise : NSObject<BANoise>

@property (nonatomic, readonly) NSArray *noises;
@property (nonatomic, readonly) NSArray *ratios; // nsnumber doubles from (0, 1]

- (instancetype)initWithNoises:(NSArray *)noises ratios:(NSArray *)ratios;
+ (BABlendedNoise *)blendedNoiseWithNoises:(NSArray *)noises ratios:(NSArray *)ratios;

@end
