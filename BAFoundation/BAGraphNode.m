//
//  BAGraphNode.m
//  BAKit
//
//  Created by Brent Gulanowski on 1/18/08.
//  Copyright 2008 Bored Astronaut. All rights reserved.
//

#import "BAGraphNode.h"


@implementation BAGraphNode


@dynamic connectedNodes;
@synthesize parentNode = parentNode;
@synthesize object = object;

#pragma mark NSObject
- (void)dealloc {
	self.connectedNodes = nil;
	self.object = nil;
	[super dealloc];
}

- (id)init {
	
	self.connectedNodes = [NSMutableSet set];
	
	return self;
}


#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)aCoder {

	if (YES == [aCoder isKindOfClass:[NSKeyedArchiver class]]) {
		[aCoder encodeObject:connectedNodes forKey:@"connectedNodes"];
	}
	else {
		[aCoder encodeObject:connectedNodes];
	}
}

- (id)initWithCoder:(NSCoder *)aCoder {
	
	if (YES == [aCoder isKindOfClass:[NSKeyedUnarchiver class]]) {
		[self setConnectedNodes:[aCoder decodeObjectForKey:@"connectedNodes"]];
	}
	else {
		[self setConnectedNodes:[aCoder decodeObject]];
	}
	
	return self;
}


#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)aZone {
	
	BAGraphNode *copy = [[[self class] alloc] init];
    
	copy->connectedNodes = [connectedNodes copy];
    copy->parentNode = [parentNode retain];
    copy->object = [object retain];
	
	return copy;
}


#pragma mark Accessors
- (NSSet *)connectedNodes {
	return [NSSet setWithSet:connectedNodes];
}

- (void)setConnectedNodes:(NSSet *)nodes {
	[connectedNodes autorelease];
	connectedNodes = [nodes mutableCopy];
}

- (void)setParentNode:(BAGraphNode *)node {
	if([self.connectedNodes containsObject:node])
		[self removeConnectedNode:node];
	[parentNode autorelease];
	parentNode = [node retain];
}


#pragma mark set mutation accessors
- (void)addConnectedNode:(BAGraphNode *)aNode {
	if( ! [[aNode object] isEqual:[self.parentNode object]])
		[connectedNodes addObject:aNode];
}

- (void)removeConnectedNode:(BAGraphNode *)aNode {
	if([[self.parentNode object] isEqual:[aNode object]])
		self.parentNode = nil;
	else
		[connectedNodes removeObject:aNode];
}

@end
