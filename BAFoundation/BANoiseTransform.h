//
//  BANoiseTransform.h
//  BAFoundation
//
//  Created by Brent Gulanowski on 2018-05-16.
//  Copyright © 2018 Lichen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <BAFoundation/BANoiseTypes.h>

@interface BANoiseTransform : NSObject {
@private
    BANoiseVector _scale;
    BANoiseVector _rotationAxis;
    BANoiseVector _translation;
    double _rotationAngle;
    double _matrix[16];
}

// These are only available if they were provided at instantiation
@property (nonatomic, readonly) BANoiseVector scale;
@property (nonatomic, readonly) BANoiseVector rotationAxis;
@property (nonatomic, readonly) BANoiseVector translation;
@property (nonatomic, readonly) double rotationAngle;

- (BOOL)isEqualToTransform:(BANoiseTransform *)transform;

- (id)initWithMatrix:(double[16])matrix;
// Rotations are about the origin
- (id)initWithScale:(BANoiseVector)scale rotationAxis:(BANoiseVector)axis angle:(double)angle;
- (id)initWithScale:(BANoiseVector)scale;
- (id)initWithRotationAxis:(BANoiseVector)axis angle:(double)angle;
- (id)initWithTranslation:(BANoiseVector)translation;

- (BANoiseTransform *)transformByPremultiplyingTransform:(BANoiseTransform *)transform;

- (BANoiseVector)transformVector:(BANoiseVector)vector;
- (BAVectorTransformer)transformer;

+ (instancetype)randomTranslation;
+ (instancetype)randomRotation;
+ (instancetype)randomScale;
+ (instancetype)randomTransform;

@end
