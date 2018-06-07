//
//  NSManagedObject+BAAdditions.m
//  Bored Astronaut Additions
//
//  Created by Brent Gulanowski on 24/02/08.
//  Copyright 2008 Bored Astronaut. All rights reserved.
//

#import <BAFoundation/NSManagedObjectContext+BAAdditions.h>
#import <BAFoundation/NSManagedObject+BAAdditions.h>

#import <BAFoundation/NSObject+PlistTransforming.h>

#import <BAFoundation/IntegerNumberTransformer.h>
#import <BAFoundation/FloatNumberTransformer.h>
#import <BAFoundation/DateTransformer.h>

#import <BAFoundation/BARelationshipProxy.h>


NSString *kBAIntegerTransformerName = @"BAIntegerTransformer";
//NSString *kBADecimalTransformerName = @"BADecimalTransformer";
NSString *kBAFloatTransformerName = @"BAFloatTransformer";
NSString *kBADateTransformerName = @"BADateTransformer";


static NSMutableDictionary *sortKeyCache;

NSSet *sortingKeys;

@implementation NSManagedObject (BAAdditions)

Class numberClass;

#pragma mark - Category Loading
+ (void)load {
	numberClass = [NSNumber class];
    NSValueTransformer *transformer = [[IntegerNumberTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:kBAIntegerTransformerName];
    [transformer release];
//    [NSValueTransformer setValueTransformer:[[DecimalNumberTransformer alloc] init] forName:kBADecimalTransformerName];
    transformer = [[FloatNumberTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:kBAFloatTransformerName];
    [transformer release];
    transformer = [[DateTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:kBADateTransformerName];
    [transformer release];
    
    sortKeyCache = [[NSMutableDictionary alloc] init];
    sortingKeys = [[NSSet alloc] initWithArray:@[@"create", @"created", @"createdAt", @"creation", @"update", @"updated", @"updatedAt", @"revise", @"revised", @"revisedAt", @"revision", @"title", @"name"]];
}


#pragma mark - Object Creation
+ (NSManagedObject *)insertObjectInManagedObjectContext:(NSManagedObjectContext *)context {
	return [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:context];
}

+ (NSManagedObject *)insertObject {
    NSAssert(BAActiveContext, @"No active managed object context");
	return [self insertObjectInManagedObjectContext:BAActiveContext];
}


#pragma mark - Entity Conveniences
+ (NSString *)entityName {
	return [[self entity] name];
}


#pragma mark - Derived Properties
- (NSArray *)attributeNames {
    return [[[self entity] attributesByName] allKeys];
}

- (NSArray *)editableAttributeNames {
    return [[self attributeNames] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT SELF ENDSWITH[c] %@", @"uuid"]];
}

- (NSArray *)relationshipNames {
    return [[[self entity] relationshipsByName] allKeys];
}

- (NSString *)objectIDString {
	return [[[self objectID] URIRepresentation] absoluteString];
}

- (NSString *)objectIDAsFileName {
    NSURL *uri = [[self objectID] URIRepresentation];
    NSString *idString = [uri host] ? [[uri host] stringByAppendingPathComponent:[uri path]] : [uri path];
    return [idString stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
}

- (NSString *)stringRepresentation {
    static SEL nameSel;
    if(!nameSel) nameSel = @selector(name);
    return [self respondsToSelector:nameSel] ? [self performSelector:nameSel] : [NSString stringWithFormat:@"%@ %p", [[self entity] name], self];
}

- (NSString *)listString {
    return [self stringRepresentation];
}


#pragma mark - Derived Property KVO Dependencies
+ (NSSet *)keyPathsForValuesAffectingListString {
    return [NSSet setWithObject:@"name"];
}


#pragma mark - Sorting

+ (NSString *)defaultSortKey {
    return nil;
}

+ (BOOL)defaultSortAscending {
    return YES;
}

#pragma mark - Property Value Conversion
- (id)valueForDataKey:(NSString *)aKey {
	id dataObject = [self valueForKey:aKey];
	if(nil != dataObject)
		return [NSKeyedUnarchiver unarchiveObjectWithData:dataObject];
	return nil;
}

- (void)setValue:(id)anObj forDataKey:(NSString *)aKey {
	[self setValue:[NSKeyedArchiver archivedDataWithRootObject:anObj] forKey:aKey];
}

- (int)intForKey:(NSString *)aKey {
	id number = [self valueForKey:aKey];
	if(NO == [number isKindOfClass:numberClass])
		[NSException raise:NSInternalInconsistencyException format:@""];
	return [number intValue];
}

- (void)setInt:(int)anInt forKey:(NSString *)aKey {
	if([self intForKey:aKey] != anInt)
		[self setValue:[NSNumber numberWithInt:anInt] forKey:aKey];
}


#pragma mark - Attribute Conveniences
- (NSAttributeDescription *)attributeForName:(NSString *)name {
    return [[[self entity] attributesByName] objectForKey:name];
}

- (NSAttributeDescription *)attributeForKeyPath:(NSString *)keyPath {
    
    NSAttributeDescription *attribute = nil;
    NSArray *comps = [keyPath componentsSeparatedByString:@"."];
    NSEntityDescription *entity = [self entity];
    
    for(NSString *key in comps) {
        
        NSRelationshipDescription *relation = [[entity relationshipsByName] objectForKey:key];
        
        if(relation)
            entity = [relation destinationEntity];
        else
            attribute = [[entity attributesByName] valueForKey:key];
    }
    
    return attribute;
}


#pragma mark - Relationship Conveniences
- (NSUInteger)countOfRelationship:(NSString *)relationshipName {
    
    NSRelationshipDescription *relationship = [self relationshipForName:relationshipName];
    
    if(!relationship)
        return [self countOfFetchedProperty:relationshipName];
    
    
    if(![self hasFaultForRelationshipNamed:relationshipName])
        return [[self valueForKey:relationshipName] count];
    
    
    NSRelationshipDescription *inverse = [relationship inverseRelationship];
    NSString *entityName = [[inverse entity] name];
    NSString *inverseKey = [inverse name];
    
    return [self.managedObjectContext countOfEntity:entityName withValue:self forKey:inverseKey];
}

- (NSRelationshipDescription *)relationshipForName:(NSString *)name {
    return [[[self entity] relationshipsByName] objectForKey:name];
}


#pragma mark - Fetched Property Conveniences
- (NSUInteger)countOfFetchedProperty:(NSString *)propertyName {
    
    id property = [[[self entity] propertiesByName] objectForKey:propertyName];
    
    if(![property isKindOfClass:[NSFetchedPropertyDescription class]])
        return 0;
    
    NSFetchRequest *fetch = [[[(NSFetchedPropertyDescription *)property fetchRequest] copy] autorelease];
    NSError *error = nil;
    
    fetch.predicate = [fetch.predicate predicateWithSubstitutionVariables:@{ @"FETCH_SOURCE" : self }];
    
    NSUInteger result = [self.managedObjectContext countForFetchRequest:fetch error:&error];
    
    if(error)
        NSLog(@"Error fetching count of fetched property %@: %@", propertyName, error);

    return result;
}

- (NSRelationshipDescription *)relationshipForFetchedProperty:(NSString *)propertyName {
    
    id property = [[[self entity] propertiesByName] objectForKey:propertyName];
    NSFetchRequest *fetch = [(NSFetchedPropertyDescription *)property fetchRequest];
    NSArray *relationships = [[self entity] relationshipsWithDestinationEntity:[fetch entity]];
    
    if([relationships count] != 1) {
        relationships = [relationships filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isToMany = 1"]];
        if([relationships count] != 1)
            return nil;
    }
    
    return [relationships lastObject];
}

- (NSEntityDescription *)destinationForFetchedProperty:(NSString *)propertyName {
    id property = [[[self entity] propertiesByName] objectForKey:propertyName];
    return [[(NSFetchedPropertyDescription *)property fetchRequest] entity];
}

- (NSArray *)relationshipProxies {
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"isToMany = 1"];
    NSArray *relationships = [[[[self entity] relationshipsByName] allValues] filteredArrayUsingPredicate:pred];
    
    NSMutableArray *array = [NSMutableArray array];
    
    for (NSRelationshipDescription *relationship in relationships)
        [array addObject:[BARelationshipProxy relationshipProxyWithObject:self relationshipName:[relationship name]]];
    
    return array;
}

- (NSArray *)virtualRelationshipProxies {
    
    NSMutableArray *proxies = [NSMutableArray array];
    NSDictionary *properties = [[self entity] propertiesByName];
    
    for (NSString *name in properties) {
        id property = [properties objectForKey:name];
        if(([property isKindOfClass:[NSRelationshipDescription class]] && [(NSRelationshipDescription *)property isToMany]) ||
           ([property isKindOfClass:[NSFetchedPropertyDescription class]]))
            [proxies addObject:[BARelationshipProxy relationshipProxyWithObject:self relationshipName:[property name]]];
    }
    
    return proxies;
}



#pragma mark - Attribute Transformation
- (NSAttributeType)attributeTypeForProperty:(NSString **)ioName owner:(NSManagedObject **)oOwner {
    
    NSString *propertyName = *ioName;
    NSArray *components = [propertyName componentsSeparatedByString:@"."];
    NSManagedObject *destination = self;
    
    if([components count] > 1) {
        
        NSString *destinationKeyPath = [[components subarrayWithRange:NSMakeRange(0, [components count]-1)] componentsJoinedByString:@"."];
        
        *ioName = propertyName = [components lastObject];
        destination = [self valueForKeyPath:destinationKeyPath];
    }
    
    if(oOwner) *oOwner = destination;
    
    NSAttributeDescription *attribute = [destination attributeForName:propertyName];
    
    if(attribute)
        return [attribute attributeType];
    
    NSRelationshipDescription *relation = [destination relationshipForName:propertyName];
    
    if(relation)
        return RELATIONSHIP_PROPERTY_TYPE;
    
    return NSUndefinedAttributeType;
}

- (NSAttributeType)attributeTypeForProperty:(NSString *)propertyName {
    return [self attributeTypeForProperty:&propertyName owner:NULL];
}

+ (NSValueTransformer *)valueTransformerForAttributeType:(NSAttributeType)type {

    NSString *transformerName = nil;
    
    switch (type) {
            
        case NSInteger16AttributeType:
        case NSInteger32AttributeType:
        case NSInteger64AttributeType:
        case NSBooleanAttributeType:
            transformerName = kBAIntegerTransformerName;
            break;

//        case NSDecimalAttributeType:
//            transformerName = kBADecimalTransformerName;
//            break;
            
        case NSFloatAttributeType:
            transformerName = kBAFloatTransformerName;
            break;
            
        case NSStringAttributeType:
            break;
            
        case NSDateAttributeType:
            transformerName = kBADateTransformerName;
            break;
            
        case NSUndefinedAttributeType:
        case NSBinaryDataAttributeType:
        default:
            return nil;
            break;
    }
    
    return [NSValueTransformer valueTransformerForName:transformerName];
}

+ (NSString *)stringForValue:(id)value attributeType:(NSAttributeType)type {
    
    if(RELATIONSHIP_PROPERTY_TYPE == type) {
        return [value stringRepresentation];
    }
    
    NSValueTransformer *transformer = [self valueTransformerForAttributeType:type];
    if(transformer)
        return [transformer reverseTransformedValue:value];
    else if(value)
        return [NSString stringWithFormat:@"%@", value];
    else
        return @"";
}

+ (id)transformedValueForString:(NSString *)value attributeType:(NSAttributeType)type {
    if(RELATIONSHIP_PROPERTY_TYPE == type) {
        // TODO: can we work out the object with just its description? We would need the entity
        return nil;
    }
    NSValueTransformer *transformer = [self valueTransformerForAttributeType:type];
    if(transformer) return [transformer transformedValue:value];
    if(NSStringAttributeType == type)
        return value;
    return nil;
}

- (NSString *)stringValueForAttribute:(NSString *)attrName {
    NSAttributeDescription *attribute = [[[self entity] attributesByName] objectForKey:attrName];
    return [[self class] stringForValue:[self valueForKey:attrName] attributeType:[attribute attributeType]];
}

- (void)setStringValue:(NSString *)value forAttribute:(NSString *)attrName {
    
    NSAttributeDescription *attribute = [[[self entity] attributesByName] objectForKey:attrName];
    id newValue = [[self class] transformedValueForString:value attributeType:[attribute attributeType]];
    
    [self setValue:newValue forKey:attrName];
}

- (NSString *)stringValueForProperty:(NSString *)propertyName {
    
    id value = [self valueForKeyPath:propertyName];
    
    return [[self class] stringForValue:value attributeType:[self attributeTypeForProperty:&propertyName owner:NULL]];
}

- (void)setStringValue:(NSString *)value forProperty:(NSString *)propertyName {
    
    NSManagedObject *owner = nil;
    NSString *ownerProp = propertyName;
    NSAttributeType type = [self attributeTypeForProperty:&ownerProp owner:&owner];
    
    if(RELATIONSHIP_PROPERTY_TYPE == type) {
        // TODO: lookup table from string description of object to actual object
        NSManagedObject *objectProperty = nil;
        [owner setValue:objectProperty forKey:ownerProp];
    }
    else
        [owner setStringValue:value forAttribute:ownerProp];
}


#pragma mark - Property List Conversion
- (void)setValuesForAttributesWithDictionary:(NSDictionary *)keyedValues safe:(BOOL)safe {
    
    if(!safe)
        keyedValues = [keyedValues dictionaryWithValuesForKeys:[self attributeNames]];
    
    [self setValuesForKeysWithDictionary:keyedValues];
}

// This is experimental and untested
// It would be better to create a more strict interface that included a plist generator and
// stored version info in the dictionary
- (void)setValuesForRelationshipsWithDictionary:(NSDictionary *)keyedValues safe:(BOOL)safe {
    
    if(!safe)
        keyedValues = [keyedValues dictionaryWithValuesForKeys:[self relationshipNames]];
    
    for (NSString *relName in keyedValues) {
        
        NSRelationshipDescription *relation = [self relationshipForName:relName];
        NSEntityDescription *entity = [relation destinationEntity];
        
        if([relation isToMany]) {
            
            NSArray *values = nil;
            NSArray *names = nil;
            id object = [keyedValues objectForKey:relName];
            
            if([object isKindOfClass:[NSArray class]])
                values = object;
            else if([object isKindOfClass:[NSSet class]])
                values = [object allObjects];
            else { // assume dictionary - manually generated
                values = [object allValues];
                if([[entity attributesByName] objectForKey:@"name"])
                    names = [object allKeys];
            }
            
            if([names count]) {
                for (NSUInteger i=[names count]-1; i != -1; --i) {
                    id relValue = [self insertNewObjectForProperty:relName];
                    [relValue setValuesWithPropertyList:[values objectAtIndex:i]];
                    [relValue setValue:[names objectAtIndex:i] forKey:@"name"];
                }
            }
            else if([values count])
                for (NSDictionary *relInfo in values)
                    [[self insertNewObjectForProperty:relName] setValuesWithPropertyList:relInfo];
        }
        else {
            [[self insertNewObjectForProperty:relName] setValuesWithPropertyList:[keyedValues objectForKey:relName]];
        }
    }
}

- (void)setValuesWithPropertyList:(NSDictionary *)plist {
    [self setValuesForAttributesWithDictionary:plist safe:NO];
    [self setValuesForRelationshipsWithDictionary:plist safe:NO];
}

- (NSDictionary *)propertyListRepresentation {
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    for(NSString *attribName in [self attributeNames])
        [dict setObject:[[self valueForKey:attribName] propertyListRepresentation] forKey:attribName];
    
    for(NSString *relName in [self relationshipNames])
        [dict setObject:[[self valueForKey:relName] propertyListRepresentation] forKey:relName];
    
    return dict;
}


#pragma mark - Relationship Forming
- (NSArray *)sortDescriptorsForRelationship:(NSString *)relName {
    static dispatch_once_t onceToken;
    static NSArray *sorts;
    dispatch_once(&onceToken, ^{
        sorts = [[NSArray alloc] initWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"objectIDString" ascending:YES], nil];
    });
    return sorts;
}

- (id)objectInRelationship:(NSString *)relName atIndex:(NSUInteger)index {

    id relation = [self valueForKey:relName];
    
    if(![relation respondsToSelector:@selector(count)]) return relation;

    return [[relation sortedArrayUsingDescriptors:[self sortDescriptorsForRelationship:relName]] objectAtIndex:index];
}

- (NSManagedObject *)insertNewObjectForProperty:(NSString *)propName {

    NSEntityDescription *relatedEntity = nil;
    NSString *relName = nil;
    id relationship = [[[self entity] propertiesByName] objectForKey:propName];
    BOOL refresh = NO;
    
    if([relationship isKindOfClass:[NSRelationshipDescription class]]) {
        relatedEntity = [relationship destinationEntity];
        relName = propName;
    }
    else if([relationship isKindOfClass:[NSFetchedPropertyDescription class]]) {
        
        relatedEntity = [self destinationForFetchedProperty:propName];
        if(!relatedEntity)
            return nil;
                
        NSArray *underlyingRelationships = [[self entity] relationshipsWithDestinationEntity:relatedEntity];
        
        if([underlyingRelationships count] == 1) {
            relationship = [underlyingRelationships lastObject];
            relName = [relationship name];
        }
        refresh = YES;
    }
    

    NSManagedObject *relatedObject = [self.managedObjectContext insertDefaultObjectForEntityNamed:[relatedEntity name]];

    if(relName) {
        if([relationship isToMany])
            [[self mutableSetValueForKey:relName] addObject:relatedObject];
        else
            [self setValue:relatedObject forKey:relName];
    }
    
    if(refresh) {
        [self willChangeValueForKey:propName];
        [self.managedObjectContext refreshObject:self mergeChanges:YES];
        [self didChangeValueForKey:propName];
    }

    return relatedObject;
}

- (void)removeObjectFromRelationship:(NSString *)relName atIndex:(NSUInteger)index {
    [[self valueForKey:relName] removeObject:[self objectInRelationship:relName atIndex:index]];
}

@end
