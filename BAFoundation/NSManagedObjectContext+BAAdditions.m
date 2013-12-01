//
//  NSManagedObjectContext+BAAdditions.m
//  Bored Astronaut Additions
//
//  Created by Brent Gulanowski on 22/02/08.
//  Copyright 2008 Bored Astronaut. All rights reserved.
//

#import <BAFoundation/NSManagedObjectContext+BAAdditions.h>
#import <BAFoundation/NSManagedObject+BAAdditions.h>


NSString *defaultStoreName = @"Data Store";


@implementation NSManagedObjectContext (BAAdditions)

static NSManagedObjectContext *activeContext;


+ (NSURL *)defaultStoreURL {

	NSString *appSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
	NSString *processName = [[NSProcessInfo processInfo] processName];
	NSString *fileName = [defaultStoreName stringByAppendingPathExtension:@"sqlite"];
    NSString *path = [NSString pathWithComponents:[NSArray arrayWithObjects:appSupport, processName, fileName, nil]];
    
    return [NSURL fileURLWithPath:path];
}

+ (NSManagedObjectContext *)newObjectContextWithModel:(NSManagedObjectModel *)model type:(NSString *)storeType storeURL:(NSURL *)url {
	
	NSManagedObjectContext *context = [[NSManagedObjectContext alloc] init];
	NSPersistentStoreCoordinator *coord = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model] autorelease];
    
	NSError *error = nil;
    NSString *directory = [[url path] stringByDeletingLastPathComponent];

	if(![[NSFileManager defaultManager] createDirectoryAtPath:directory
								  withIntermediateDirectories:YES
												   attributes:nil
														error:&error]) {
        BOOL isDirectory = NO;
        if(![[NSFileManager defaultManager] fileExistsAtPath:directory isDirectory:&isDirectory] || !isDirectory)
            NSLog(@"Error creating directory: %@", error);
    }

    NSPersistentStore *store = [coord addPersistentStoreWithType:storeType configuration:nil URL:url options:nil error:&error];
	
	if(nil == store)
		NSLog(@"Error creating persistent store at path '%@'. Error: '%@'.", url, error);
	
	[context setPersistentStoreCoordinator:coord];
	[self setActiveContext:context];
	
	return context;
}

+ (NSManagedObjectContext *)newObjectContextWithModel:(NSManagedObjectModel *)model {
	return [self newObjectContextWithModel:model type:NSSQLiteStoreType storeURL:[self defaultStoreURL]];
}

+ (NSManagedObjectContext *)newObjectContextWithModelName:(NSString *)name {
	
	NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"mom"];
    
    if(!path)
        path = [[NSBundle mainBundle] pathForResource:name ofType:@"momd"];
    
	NSManagedObjectModel *model = [[[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path]] autorelease];
									
	return [self newObjectContextWithModel:model];
}

+ (NSManagedObjectContext *)newObjectContext {
    return [self newObjectContextWithModelName:[[NSProcessInfo processInfo] processName]];
}

+ (NSManagedObjectContext *)activeContext {
	return activeContext;
}

+ (void)setActiveContext:(NSManagedObjectContext *)context {
    [activeContext release];
	activeContext = [context retain];
}

- (void)makeActive {
	[NSManagedObjectContext setActiveContext:self];
}

- (NSManagedObjectContext *)editingContext {
        
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(editorSaved:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:moc];
    moc.persistentStoreCoordinator = self.persistentStoreCoordinator;

    return [moc autorelease];
}

- (void)editorSaved:(NSNotification *)note {
    [self mergeChangesFromContextDidSaveNotification:note];
//    [[note object] reset];
}

- (NSArray *)entityNames {
    return [[[[self persistentStoreCoordinator] managedObjectModel] entities] valueForKey:@"name"];
}

- (NSEntityDescription *)entityForName:(NSString *)entityName {
    return [NSEntityDescription entityForName:entityName inManagedObjectContext:self];
}

- (NSUInteger)countOfEntity:(NSString *)entityName withPredicate:(NSPredicate *)predicate {
    
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:entityName];
    fetch.predicate = predicate;
    
    NSError *error = nil;
    NSUInteger result = [self countForFetchRequest:fetch error:&error];
    
    if(result == NSNotFound) {
        NSLog(@"Count of %@ objects failed; error: %@", entityName, error);
        return 0;
    }
    
    return result;
}

- (NSUInteger)countOfEntity:(NSString *)entityName withValue:(id)value forKey:(NSString *)key {
    return [self countOfEntity:entityName withPredicate:[NSPredicate predicateWithFormat:@"%K = %@", key, value]];
}

- (NSUInteger)countOfEntity:(NSString *)entityName {
    return [self countOfEntity:entityName withPredicate:nil];
}

+ (NSPredicate *)predicateForValue:(id)aValue key:(NSString *)aKey {
    
	NSPredicate *pred = nil;
	
    if(nil != aValue && nil != aKey) {
        if([aValue isKindOfClass:[NSString class]]) {
            NSString *format = [NSString stringWithFormat:@"%@ LIKE[c] ", aKey];
            format = [format stringByAppendingString:@"%@"];
            pred = [NSPredicate predicateWithFormat:format, aValue];
        }
        else {
            pred = [NSPredicate predicateWithFormat:@"%K = %@", aKey, aValue];
        }
	}
    
    return pred;
}

- (NSArray *)objectsForEntityNamed:(NSString *)entityName matchingPredicate:(NSPredicate *)aPredicate limit:(NSUInteger)limit {
	
	NSArray *result = nil;
	NSFetchRequest *fetch = [[[NSFetchRequest alloc] init] autorelease];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self];
    Class class = NSClassFromString([entity managedObjectClassName]);
	NSError *error = nil;
	
	if(nil != aPredicate)
		[fetch setPredicate:aPredicate];
    
    if(limit > 0)
        [fetch setFetchLimit:limit];

	[fetch setEntity:entity];
    [fetch setSortDescriptors:[class defaultSortDescriptors]];

	result = [self executeFetchRequest:fetch error:&error];
	if(nil != error) {
		NSLog(@"Please respond to this error: %@", error);
	}
	
	return result;
}

- (NSArray *)objectsForEntityNamed:(NSString *)entityName matchingPredicate:(NSPredicate *)aPredicate {
    return [self objectsForEntityNamed:entityName matchingPredicate:aPredicate limit:0];
}

- (NSArray *)objectsForEntityNamed:(NSString *)entity matchingValue:(id)aValue forKey:(NSString *)aKey {
    return [self objectsForEntityNamed:entity matchingPredicate:[[self class] predicateForValue:aValue key:aKey] limit:0];
}

- (NSArray *)objectsForEntityNamed:(NSString *)entity {
    return [self objectsForEntityNamed:entity matchingPredicate:nil];
}

- (id)objectForEntityNamed:(NSString *)entity matchingPredicate:(NSPredicate *)aPredicate {
	return [[self objectsForEntityNamed:entity matchingPredicate:aPredicate limit:1] lastObject];
}

- (id)objectForEntityNamed:(NSString *)entity matchingValue:(id)aValue forKey:(NSString *)aKey {
	return [[self objectsForEntityNamed:entity matchingPredicate:[[self class] predicateForValue:aValue key:aKey] limit:1] lastObject];
}

- (id)objectForEntityNamed:(NSString *)entity {
    return [self objectsForEntityNamed:entity matchingPredicate:nil limit:1];
}

- (id)objectForEntityNamed:(NSString *)entity matchingValue:(id)aValue forKey:(NSString *)aKey create:(BOOL*)create {
	
	id object = nil;
	
	if(aValue && aKey)
        object = [self objectForEntityNamed:entity matchingValue:aValue forKey:aKey];
	
	if(create && *create) {
		if(object) {
			*create = NO;
		}
		else {
			object = [self insertDefaultObjectForEntityNamed:entity];
			[object setValue:aValue forKey:aKey];
		}
	}
	
	return object;
}

- (NSManagedObject *)objectWithIDString:(NSString *)IDString {
    NSManagedObjectID *objectID = [[self persistentStoreCoordinator] managedObjectIDForURIRepresentation:[NSURL URLWithString:IDString]];
	return objectID ? [self existingObjectWithID:objectID error:NULL] : nil;
}

- (NSManagedObject *)insertDefaultObjectForEntityNamed:(NSString *)entityName {
    
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"insertDefault%@", entityName]);
    
    if([self respondsToSelector:selector]) {
        return [self performSelector:selector];
    }
    else {
        selector = NSSelectorFromString([NSString stringWithFormat:@"insert%@", entityName]);
        if([self respondsToSelector:selector])
            return [self performSelector:selector];
    }
    
    return [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self];
}

@end
