//
//  NSObject+PlistTransforming.h
//  Cavebot
//
//  Created by Brent Gulanowski on 12-08-29.
//  Copyright (c) 2012 Lichen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (BAFPlistTransforming)

@property (nonatomic, readonly, getter=baf_propertyListRepresentation) id propertyListRepresentation;

// Classes should override this for their to-many relationships
+ (Class)baf_classForCollectionProperty:(NSString *)propertyName;

- (instancetype)initWithPropertyList:(id)propertyList class:(Class)cls;

@end

@interface NSDictionary (BAFPlistTransforming)

- (NSDictionary *)baf_mapForClass:(Class)class;

@end
