//
//  BATextIOHandler.m
//  Escape
//
//  Created by Brent Gulanowski on 11/27/05.
//  Copyright 2005 Bored Astronaut. All rights reserved.
//

#import "BATextIOHandler.h"


@interface BATextIOHandler (BATextIOHandler_private)
- (void)receive;
@end


@implementation BATextIOHandler


/** inheritance tree overrides **/
#pragma mark NSObject
#if 0  /* remove the guards as necessary */
+(void)initialize {
}
#endif

- (id)init {
	return [self initWithInputFile:nil outputFile:nil];
}


/** new methods **/
#pragma mark BATextIOHandler
- (id)initWithInputFile:(NSString *)inFile outputFile:(NSString *)outFile {
	[self setInputFile:inFile];
	[self setOutputFile:outFile];

    return self;
}

- (void)dealloc {
	[prompt release];
	[super dealloc];
}

- (NSString *)prompt {
	return [[prompt copy] autorelease];
}

- (void)setPrompt:(NSString *)newPrompt {
	[prompt autorelease];
	prompt = [newPrompt retain];
}

- (void)write:(NSString *)text {
	if(text) {
		[outputFH writeData:[text dataUsingEncoding:NSUTF8StringEncoding]];
	}
}

- (void)writeLine:(NSString *)text {
	if(text) {
		[self write:@"  "];
		[self write:text];
		[self write:@"\n"];
	}
	if(delegate) {
		[self write:prompt];
	}
}

- (void)setInputFile:(NSString *)inFile {
	inputFH = [[NSFileHandle fileHandleForReadingAtPath:inFile] retain];
	if(nil == inputFH) {
		inputFH = [NSFileHandle fileHandleWithStandardInput];
	}
}

- (void)setOutputFile:(NSString *)outFile {
	outputFH = [[NSFileHandle fileHandleForWritingAtPath:outFile] retain];
	if(nil == outputFH) {
		outputFH = [NSFileHandle fileHandleWithStandardOutput];
	}
}

- (id)delegate {
	return delegate;
}

- (void)setDelegate:(id)del {
	if(del) {
		if(NO == [del respondsToSelector:NSSelectorFromString(@"processInput:")]) {
			NSLog(@"Delegate must implement -processInput: method.");
			delegate = nil;
		}
		else if (!delegate) {
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:NSSelectorFromString(@"receive")
														 name:NSFileHandleDataAvailableNotification
													   object:inputFH];
		}
	}
    delegate = del;
    if(delegate) {
        [inputFH waitForDataInBackgroundAndNotify];
    }
    else {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}


#pragma mark BATextIOHandler_private
- (void)receive {

	NSData *data = [inputFH availableData];

	 /* should always be true if "-receive" is called */
	if(delegate) {
		
		NSString *read;
		
		if(!data || [data length] == 0) {
			[delegate processInput:nil];
		}
		else {
			read = [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];

			if([read length] == 1 && [read characterAtIndex:0] == '\n') {
				[self write:prompt];
			}
			else {
				read = [read stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
				[self writeLine:[delegate processInput:read]];
			}
		}
	}
	if(delegate) {
		[inputFH waitForDataInBackgroundAndNotify];
	}
}


@end
