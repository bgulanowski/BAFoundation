//
//  BACoreDataManager.m
//
//  Created by Brent Gulanowski on 09-10-22.
//  Copyright 2009 Bored Astronaut. All rights reserved.
//

#import <BAFoundation/BACoreDataManager.h>

#import <BAFoundation/NSManagedObjectContext+BAAdditions.h>


@interface BACoreDataManager ()

- (BOOL)moveAsideOldStore;

@end



@implementation BACoreDataManager

@synthesize model, context, editingContext, storeURL, storeUnreadable, readOnly, saveDelay, editCount;


#pragma mark - NSObject
- (void)dealloc {
    self.model = nil;
    self.context = nil;
    self.editingContext = nil;
    self.storeURL = nil;
    [super dealloc];
}

- (NSURL *)modelURL {
    
    Class class = [self class];
    NSString *path = nil;
    
    do {
        NSString *className = NSStringFromClass(class);
        
        path = [[NSBundle bundleForClass:class] pathForResource:className ofType:@"mom"];
        if(nil == path) path = [[NSBundle bundleForClass:class] pathForResource:className ofType:@"momd"];
        
        class = [class superclass];
    } while (class && !path);
    
    return [NSURL fileURLWithPath:path];
}

- (NSManagedObjectModel *)model {
	
    if(!model) {
        @synchronized(self) {
            if(!model)
                model = [[NSManagedObjectModel alloc] initWithContentsOfURL:[self modelURL]];
        }
	}
    
	return model;
}

- (NSManagedObjectContext *)context {
	
    if(!context) {
        @synchronized(self) {
            if(nil == context) {
                context = [NSManagedObjectContext newObjectContextWithModel:self.model
                                                                       type:[[self class] defaultStoreType]
                                                                   storeURL:self.storeURL];
                [context setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
            }
        }
    }
    
	return context;
}

- (NSManagedObjectContext *)editingContext {
    
    if(!editingContext) {
        @synchronized(self) {
            if(!editingContext)
                editingContext = [[self.context editingContext] retain];
        };
    }
    
    return editingContext;
}

- (NSURL *)storeURL {
    if(!storeURL) {
        @synchronized(self) {
            if(!storeURL)
                storeURL = [[self class] defaultStoreURL];
        }
    }
    return storeURL;
}


#pragma mark - Designated Initializer

- (id)initWithStoreURL:(NSURL *)url {
	self = [super init];
	if(self) {
        self.storeURL = url;
        self.saveDelay = 5;
	}
	return self;
}


#pragma mark - BACoreDataManager
- (BOOL)save {
	
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:_cmd object:nil];

	if(readOnly)
		return YES;
	
	if(storeUnreadable)
		return NO;
	
    BOOL success = YES;
	NSError *error = nil;
    
    NSAssert(context != nil, @"No managed object context!");
	
	@try {
#ifdef DEBUG
        if(editCount)
            NSLog(@"Not saving editing context; edits in progress");
#endif
        if(editingContext && !editCount && !(success = [editingContext save:&error]))
            NSLog(@"Could not save editing context: %@", error);
        else if(!(success = [context save:&error]))
            NSLog(@"Could not save context: %@", error);
        if(!editCount)
            [editingContext reset];
	}
	@catch (NSException * e) {
		NSLog(@"Exception saving core data database: '%@'.", e);
		[self setStoreUnreadable:YES];
	}
    
#ifdef DEBUG
    NSLog(@"%@ saved", self);
#endif
    
	return success;
}

- (void)scheduleSave {
    static SEL saveSelector;
    if(!saveSelector)
        saveSelector = @selector(save);
    [self performSelector:saveSelector withObject:nil afterDelay:saveDelay];
}

- (void)startEditing {
    editCount++;
}

- (void)endEditing {
    NSAssert(editCount > 0, @"Unbalanced call to endEditing");
    editCount--;
}

- (void)resetEditCount {
    if(editCount != 0) {
        NSLog(@"Resetting edit count; edit count was %u", (unsigned int)editCount);
        editCount = 0;
    }
}

- (void)cancelEdits {
    [self endEditing];
    if(!editCount)
        [editingContext rollback];
}

// TODO: convert to error handler
- (BOOL)moveAsideOldStore {
	
	BOOL success = YES;
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *storePath = [[self storeURL] path];
	NSString *destPath = [NSString stringWithFormat:@"%@-old.%@", [storePath stringByDeletingPathExtension], [storePath pathExtension]];
	NSError *error = nil;
	
	NSLog(@"Attempting to move aside old persistent store and re-create...");
	
	if([fm fileExistsAtPath:destPath] && ! [fm removeItemAtPath:destPath error:&error]) {
		NSLog(@"...unable to delete existing old persistent store at path '%@'. Error: '%@'.", destPath, error);
		success = NO;
	}
	else if( ! [fm moveItemAtPath:storePath toPath:destPath error:&error]) {
		NSLog(@"...unable to move aside old store; please ensure that the folder '%@' exists and is readable by %@. Error: %@",
				   [storePath stringByDeletingLastPathComponent], [[[NSProcessInfo processInfo] environment] objectForKey:@"LOGNAME"], error);
		success = NO;
	}
	
	return success;
}

- (void)refreshObjects:(NSArray *)objects {
	if([objects count] < 1) {
		[[self context] reset];
	}
	else {
		[[self context] setStalenessInterval:1];
		NSEnumerator *iter = [objects objectEnumerator];
		id obj;
		while (obj = [iter nextObject]) {
			[[self context] refreshObject:obj mergeChanges:YES];
		}
		[[self context] setStalenessInterval:0];
	}	
}

- (void)refreshObjectsWithURIs:(NSArray *)objectURIs {
	
	NSMutableArray *objects = [NSMutableArray arrayWithCapacity:[objectURIs count]];
	NSEnumerator *iter = [objectURIs objectEnumerator];
	NSString *uri;
	
	while(uri = [iter nextObject]) {
		
		NSManagedObjectID *objectID = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation:[NSURL URLWithString:uri]];
		
		if(nil != objectID)
			[objects addObject:[[self context] objectWithID:objectID]];
		else
			NSLog(@"Unabled to find object with managedObjectID URI %@.%@", uri, nil == objectID ? @"(Object ID not found.)" : @"");
	}
	
	if([objects count])
		[self refreshObjects:objects];
}

- (void)deleteObject:(NSManagedObject *)object {
	
    NSManagedObjectContext *objectContext = [object managedObjectContext];

	@try {
		[objectContext deleteObject:object];
	}
	@catch (NSException * e) {
		NSLog(@"Error attempting to delete managed object. Rolling back context.");
		[objectContext rollback];
	}
	@finally {
		[self save];
	}
}

+ (NSString *)defaultStoreType { return NSSQLiteStoreType; }

+ (NSString *)defaultStoreExtension {

    NSString *storeType = [self defaultStoreType];
    
    if([storeType isEqualToString:NSSQLiteStoreType])
        return @"sqlite";
    else if([storeType isEqualToString:NSBinaryStoreType])
        return @"coredata";
#if ! TARGET_OS_IPHONE
    else if([storeType isEqualToString:NSXMLStoreType])
        return @"xml";
#endif
    else
        return nil;
}

+ (NSString *)defaultStoreFileName {
    return [[NSProcessInfo processInfo] processName];
}

+ (NSString *)defaultStoreLocation {
    NSString *appSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
    return [appSupport stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]];
}

+ (NSURL *)defaultStoreURL {
    NSString *name = [[self defaultStoreFileName] stringByAppendingPathExtension:[self defaultStoreExtension]];
    NSString *path = [[self defaultStoreLocation] stringByAppendingPathComponent:name];
    return [NSURL fileURLWithPath:path];
}

+ (id)newCoreDataManager {
    return [[self alloc] initWithStoreURL:[self defaultStoreURL]];
};


#pragma mark - Notification handlers
- (void)editorSaved:(NSNotification *)note {
    NSLog(@"Merging changes from editing context");
    [context mergeChangesFromContextDidSaveNotification:note];
}

@end


#if TARGET_OS_IPHONE
@implementation UIApplication (BAAdditions)

- (BACoreDataManager *)modelManager {
    if([[self delegate] conformsToProtocol:@protocol(BAApplicationDelegateAdditions)])
        return [(id<BAApplicationDelegateAdditions>)[self delegate] modelManager];
    return nil;
}

+ (BACoreDataManager *)modelManager {
    return [[self sharedApplication] modelManager];
}

@end
#endif
