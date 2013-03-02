//
//  BARelationshipProxy.m
//  BAFoundation
//
//  Created by Brent Gulanowski on 12-12-06.
//  Copyright (c) 2012 Bored Astronaut. All rights reserved.
//

#import "BARelationshipProxy.h"
#import "NSManagedObject+BAAdditions.h"


@implementation BARelationshipProxy

@synthesize relationshipName=_relationshipName;
@synthesize object=_object;

- (id)initWithObject:(id)object relationshipName:(NSString *)relationshipName {
    self = [super init];
    
    if(self) {
        self.object = object;
        self.relationshipName = relationshipName;
    }
    
    return self;
}

- (id)insertObject {
    return [_object insertNewObjectForProperty:_relationshipName];
}

+ (BARelationshipProxy *)relationshipProxyWithObject:(id)object relationshipName:(NSString *)relationshipName {
    return [[[self alloc] initWithObject:object relationshipName:relationshipName] autorelease];
}

@end
