//
//  BAKeyValuePair.h
//  BAFoundation
//
//  Created by Brent Gulanowski on 2016-07-03.
//  Copyright © 2016 Bored Astronaut. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BAKeyValuePair<KeyType, ValueType> : NSObject<NSCopying>

@property (nonatomic, readonly) KeyType<NSCopying> key;
@property (nonatomic, readonly) ValueType value;

- (instancetype)initWithKey:(KeyType<NSCopying>)key value:(ValueType)value;
+ (instancetype)keyValuePairWithKey:(KeyType<NSCopying>)key value:(ValueType)value;

@end
