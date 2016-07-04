//
//  BATestObject.h
//  BAFoundation
//
//  Created by Brent Gulanowski on 2016-07-04.
//  Copyright © 2016 Lichen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BATestObject : NSObject

@property _Bool c99Boolean;
@property BOOL objcBoolean;
@property char character;
@property NSInteger integer;
@property CGFloat cgFloat;
@property char *cString;

@property (strong) id object;
@property (strong) NSDate *date;
@property (strong) NSData *data;
@property (strong) NSNumber *number;
@property (strong) NSString *string;

@property (strong) NSArray *array;
@property (strong) NSSet *set;
@property (strong) NSOrderedSet *orderedSet;
@property (strong) NSDictionary *dictionary;

@property Class cls;

@end
