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

+ (instancetype)baf_objectForPropertyList:(id)propertyList;

+ (NSArray *)baf_objectsForPropertyList:(NSArray *)propertyList;

// Classes should override this for their to-many relationships
+ (Class)baf_contentClassForCollectionKey:(NSString *)key;

@end
