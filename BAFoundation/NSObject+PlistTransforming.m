//
//  NSObject+PlistTransforming.m
//  Cavebot
//
//  Created by Brent Gulanowski on 12-08-29.
//  Copyright (c) 2012 Lichen Labs. All rights reserved.
//

#import <BAFoundation/NSObject+PlistTransforming.h>

@implementation NSObject (PlistTransforming)
- (id)propertyListRepresentation { return nil; }
- (BOOL)supportsPlistTransforming { return NO; }
@end

@implementation NSNumber (PlistTransforming)
- (id)propertyListRepresentation { return self; }
- (BOOL)supportsPlistTransforming { return YES; }
@end

@implementation NSString (PlistTransforming)
- (id)propertyListRepresentation { return self; }
- (BOOL)supportsPlistTransforming { return YES; }
@end

@implementation NSData (PlistTransforming)
- (id)propertyListRepresentation { return self; }
- (BOOL)supportsPlistTransforming { return YES; }
@end

@implementation NSDate (PlistTransforming)
- (id)propertyListRepresentation { return self; }
- (BOOL)supportsPlistTransforming { return YES; }
@end

@implementation NSArray (PlistTransforming)
- (id)propertyListRepresentation {
    return [self valueForKey:NSStringFromSelector(_cmd)];
}
- (BOOL)supportsPlistTransforming {
    return ![[self valueForKey:NSStringFromSelector(_cmd)] containsObject:[NSNumber numberWithBool:NO]];
}
@end

@implementation NSDictionary (PlistTransforming)
- (id)propertyListRepresentation {
    return [NSDictionary dictionaryWithObjects:[[self allValues] propertyListRepresentation] forKeys:[self allKeys]];
}
- (BOOL)supportsPlistTransforming {
    return [[self allValues] supportsPlistTransforming];
}
@end
