//
//  BANumber.h
//  BAFoundation
//
//  Created by Brent Gulanowski on 2018-07-13.
//  Copyright © 2018 Lichen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BANumber : NSObject

@property (nonatomic, readonly) NSUInteger base;
@property (nonatomic, readonly) NSUInteger size;
@property (nonatomic, readonly) NSUInteger value;

- (instancetype)initWithBase:(NSUInteger)base size:(NSUInteger)size initialValue:(NSUInteger)value NS_DESIGNATED_INITIALIZER;

- (void)increment;
- (NSUInteger)digitAtPlace:(NSUInteger)place;

@end
