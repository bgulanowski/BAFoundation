 //
//  BABitArray.m
//
//  Created by Brent Gulanowski on 09-09-27.
//  Copyright 2009 Bored Astronaut. All rights reserved.
//

#import "BABitArray.h"

#import "NSData+GZip.h"


// These functions are meant to alter bits in a single byte, not an array of bytes
static void setBits(unsigned char *byte, NSUInteger start, NSUInteger end);
static void clearBits(unsigned char *byte, NSUInteger start, NSUInteger end);


NSUInteger hammingWeight(unsigned char *bytes, NSRange range);

NSInteger copyBits(unsigned char *bytes, BOOL *bits, NSRange range, BOOL write);
NSUInteger setRange(unsigned char *bytes, NSRange range, BOOL set);


@interface BABitArray ()

- (id)initWithLength:(NSUInteger)bits;

@property (readwrite) NSUInteger count;

@end



@implementation BABitArray

@synthesize length, count, enableArchiveCompression;


NSUInteger bitsInChar = NSNotFound;

#pragma mark - Accessors
- (NSData *)bufferData {
    return [NSData dataWithBytes:buffer length:bufferLength];
}


#pragma mark - NSObject
+ (void)initialize {
	if(NSNotFound == bitsInChar) {
		bitsInChar = sizeof(char)*8;
//		NSLog(@"bits in char: %u", bitsInChar);
	}
}

- (id)init {
	return [self initWithLength:0];
}

- (void)dealloc {
	if (length > 0)
		free(buffer);
	[super dealloc];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@ length:%lu count:%lu; first bit: %@; last bit: %@; first set bit: %lu; first clear bit: %lu; last set bit: %lu; last clear bit: %lu",
			[super description], (unsigned long)length, (unsigned long)count, [self bit:0]?@"YES":@"NO", [self bit:length-1]?@"YES":@"NO",
			(unsigned long)[self firstSetBit], (unsigned long)[self firstClearBit], (unsigned long)[self lastSetBit], (unsigned long)[self lastClearBit]];
}

- (BOOL)isEqual:(id)object {
	
	BABitArray *ba = (BABitArray *)object;

	return (count == ba->count &&
			length == ba->length &&
			bufferLength == ba->bufferLength &&
			!memcmp(buffer, ba->buffer, bufferLength));
}


#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone {
	
	BABitArray *copy = [[[self class] alloc] init];
    
    copy->bufferLength = self->bufferLength;
    copy->length = self->length;
    copy->count = self->count;
	
	copy->buffer = malloc(bufferLength*sizeof(unsigned char));
	memcpy(copy->buffer, buffer, bufferLength * sizeof(char));
	
	return copy;
}


#pragma mark - NSCoding
- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    NSData *data = [NSData dataWithBytesNoCopy:buffer length:bufferLength freeWhenDone:NO];
    NSString *key = @"data";
    if(enableArchiveCompression) {
        data = [data gzipDeflate];
        key = @"gzippedData";
    }
    
    [aCoder encodeObject:data forKey:key];
    [aCoder encodeInteger:(NSInteger)length forKey:@"length"];
    [aCoder encodeBool:enableArchiveCompression forKey:@"compressed"];
    [aCoder encodeInteger:count forKey:@"count"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    NSData *data = [aDecoder decodeObjectForKey:@"data"] ?: [[aDecoder decodeObjectForKey:@"gzippedData"] gzipInflate];
    self = [self initWithData:data length:[aDecoder decodeIntegerForKey:@"length"]];
    if(self) {
        enableArchiveCompression = [aDecoder decodeBoolForKey:@"compressed"];
        
        NSUInteger storedCount = [aDecoder decodeIntegerForKey:@"count"];
        
        if(storedCount != count)
            NSLog(@"Count is wrong for bit array. Expected: %d; actual: %d", (int)storedCount, (int)count);
    }
    return self;
}


#pragma mark - BABitArray
- (id)initWithData:(NSData *)data length:(NSUInteger)bitsLength {
    self = [super init];
    if(self) {
        bufferLength = [data length];
        buffer = malloc(bufferLength);
        
        if(buffer)
            [data getBytes:buffer length:bufferLength];
        length = bitsLength;
        [self refreshCount];
    }
    return self;
}

- (id)initWithBitArray:(BABitArray *)otherArray range:(NSRange)bitRange {
    return [self initWithData:[otherArray dataForRange:bitRange] length:bitRange.length];
}

- (BOOL)bit:(NSUInteger)index {
	if(index > length)
		[NSException raise:NSInvalidArgumentException format:@"index beyond bounds: %lu", (unsigned long)index];
	
	NSUInteger byte = index/bitsInChar;
	NSUInteger bit = index%bitsInChar;
	
//	NSLog(@"Checking bit %u in byte %u (0x%02X): 0x%02X", bit, byte, buffer[byte], (buffer[byte] & (1 << bit)));
	return (BOOL)((buffer[byte] & (1 << bit)) != 0);
}

- (void)setBit:(NSUInteger)index {
	if(index > length)
        [NSException raise:NSInvalidArgumentException format:@"index beyond bounds: %lu", (unsigned long)index];

	NSUInteger byte = index/bitsInChar;
	NSUInteger bit = index%bitsInChar;
	unsigned char mask = (1 << bit);
	
	if(! (buffer[byte] & mask)) {
		buffer[byte] |= mask;
		++count;
	}
}

- (void)setRange:(NSRange)bitRange {
    NSUInteger maxIndex = bitRange.location+bitRange.length-1;
	if(maxIndex >= length)
		[NSException raise:NSInvalidArgumentException format:@"index beyond bounds: %lu", (unsigned long)maxIndex];
	count += setRange(buffer, bitRange, YES);
    NSAssert([self checkCount], @"Count incorrect after setting range");
}

- (void)setAll {
	memset(buffer, 0xff, bufferLength);
	count = length;
}

- (void)clearBit:(NSUInteger)index {
	if(index > length)
		[NSException raise:NSInvalidArgumentException format:@"index beyond bounds: %lu", (unsigned long)index];
	NSUInteger byte = index/bitsInChar;
	NSUInteger bit = index%bitsInChar;
	unsigned char mask = (1 << bit);
	
	if(buffer[byte] & mask) {
		buffer[byte] &= ~mask;
		--count;
	}	
}

- (void)clearRange:(NSRange)bitRange {
    NSUInteger maxIndex = bitRange.location+bitRange.length-1;
	if(maxIndex >= length)
		[NSException raise:NSInvalidArgumentException format:@"index beyond bounds: %lu", (unsigned long)maxIndex];
	count -= setRange(buffer, bitRange, NO);
    NSAssert([self checkCount], @"Count incorrect after setting range");
}

- (void)clearAll {
	memset(buffer, 0, bufferLength);
	count = 0;
}

- (NSUInteger)first:(unsigned char *)p {
    
	unsigned char t=1;
	NSUInteger b=0;
	
	while(!*p && p++<buffer+bufferLength-1);
    
    if(p-buffer>=bufferLength)
        return NSNotFound;
    
	while(b<bitsInChar && !(*p>>b&t)) b++;
    
    if(b>=bitsInChar)
        return NSNotFound;
	
	return (p-buffer)*bitsInChar+b;
}

- (NSUInteger)firstSetBit {
    return [self first:buffer];
}

- (NSUInteger)lastSetBit {

	unsigned char *p = buffer+bufferLength-1;
	unsigned char b=(bitsInChar-1), t=1;

	while(!*p && p-->=buffer);
    
    if(p < buffer)
        return NSNotFound;

	while(b>0 && !(*p>>b&t)) b--;
    
    if(b>=bitsInChar)
        return NSNotFound;

	return (p-buffer)*bitsInChar+b;
}

- (void)readBits:(BOOL *)bits range:(NSRange)range {
    copyBits(buffer, bits, range, NO);
}

- (void)writeBits:(BOOL *const)bits range:(NSRange)range {
    count+=copyBits(buffer, bits, range, YES);
}

- (void)readBytes:(unsigned char *)bytes range:(NSRange)byteRange {
    NSUInteger maxIndex = byteRange.location+byteRange.length-1;
	if(maxIndex >= bufferLength)
		[NSException raise:NSInvalidArgumentException format:@"index beyond bounds: %lu", (unsigned long)maxIndex];
    memcpy(bytes, buffer, byteRange.length);
}

- (void)writeBytes:(unsigned char *)bytes range:(NSRange)byteRange {
    
    NSUInteger maxIndex = byteRange.location+byteRange.length-1;
	if(maxIndex >= bufferLength)
		[NSException raise:NSInvalidArgumentException format:@"index beyond bounds: %lu", (unsigned long)maxIndex];

    NSRange bitRange = NSMakeRange(0, byteRange.length*bitsInChar);
    NSInteger newCount = hammingWeight(bytes, bitRange);
    NSInteger oldCount = hammingWeight(buffer+byteRange.location, bitRange);
    
    memcpy(buffer, bytes, byteRange.length);
    
    count += newCount-oldCount;
}

- (NSData *)dataForRange:(NSRange)bitRange {
    
    size_t bytesLength = (bitRange.length+7)/bitsInChar;
    
    if(bitRange.location%bitsInChar == 0)
        return [NSData dataWithBytes:buffer + (bitRange.location/bitsInChar) length:bytesLength];
    
    unsigned char *subBuffer = malloc(sizeof(unsigned char)*bytesLength);
    
    union {
        unsigned char c8[2];
        uint16_t c16;
    } pair;
    
	NSUInteger first = bitRange.location/bitsInChar;
	NSUInteger start = bitRange.location%bitsInChar;
	NSUInteger last  = (bitRange.location+bitRange.length-1)/bitsInChar;
	NSUInteger end   = (bitRange.length)%bitsInChar;
    
    for (NSUInteger i=first; i<last; ++i) {
        pair.c8[0] = buffer[i];
        pair.c8[1] = buffer[i+1];
        pair.c16 >>= start;
        subBuffer[i-first] = pair.c8[0];
    }
    
    if(bytesLength*bitsInChar > bitRange.length)
        clearBits(subBuffer+bytesLength-1, end, bitsInChar-1);
    
    return [NSData dataWithBytesNoCopy:subBuffer length:bytesLength freeWhenDone:YES];
}

- (NSUInteger)firstClearBit {
	
	unsigned char *p = buffer;
	unsigned char b=0, t=1;

	while(!(unsigned char)~*p && p++<buffer+bufferLength-1);

    if(p-buffer>=bufferLength)
        return NSNotFound;
    
    while(b<bitsInChar && !(~*p>>b&t)) b++;

    if(b>=bitsInChar)
        return NSNotFound;
    
	return (p-buffer)*bitsInChar+b;
}

- (NSUInteger)lastClearBit {
	
	unsigned char *p = buffer+bufferLength-1;
	unsigned char b=(bitsInChar-1), t=1;
	
    while(!(unsigned char)~*p && p-->=buffer);
    
    if(p < buffer)
        return NSNotFound;
    
	while(b>0 && !(~*p>>b&t)) b--;
    
    if(b>=bitsInChar)
        return NSNotFound;

	return (p-buffer)*bitsInChar+b;
}

- (NSUInteger)nextAfter:(NSUInteger)prev {
    
	unsigned char *p = buffer + prev/bitsInChar;
    unsigned char t=1;
	NSUInteger b=prev%bitsInChar+1;
	
    while(b<bitsInChar && !(*p>>b&t)) b++;

    if(b < bitsInChar)
        return (p-buffer)*bitsInChar+b;
    
    return [self first:p+1];
}

- (void)enumerate:(BABitArrayEnumerator)block {
    
    NSUInteger b = [self firstSetBit];
    NSUInteger c = 0;
    
    while(b != NSNotFound) {
        NSAssert(++c <= count, @"mis-count in -[BABitArray enumerate:]");
        block(b);
        b = [self nextAfter:b];
    }
}

- (id)initWithLength:(NSUInteger)bits {
	if(bits > 256*256*256)
		[NSException raise:NSInvalidArgumentException format:@"Requested unreasonable length for bit array (%lu)", (unsigned long)bits];
	self = [super init];
	if(self) {
		length = bits; // never changes
		bufferLength = bits/bitsInChar + ((bits%bitsInChar) > 0 ? 1 : 0);
		self.count = 0;
		if(length > 0) {
			buffer = calloc(bufferLength, sizeof(unsigned char));
			if(NULL == buffer) {
				[NSException raise:@"" format:@"Could not allocate memory; requested size: %lu", (unsigned long)bufferLength];
			}
//			NSLog(@"Allocated bit array; length: %u; buffer length: %u; buffer: %x", length, bufferLength, buffer);
		}
	}
	return self;
}

- (BOOL)checkCount {
	return hammingWeight(buffer, NSMakeRange(0, length)) == count;
}

- (void)refreshCount {
	count = hammingWeight(buffer, NSMakeRange(0, length));
}


#pragma mark Factories
+ (BABitArray *)bitArrayWithLength:(NSUInteger)bits {
	return [[[self alloc] initWithLength:bits] autorelease];
}
+ (BABitArray *)bitArray8 {
	return [[[self alloc] initWithLength:8] autorelease];
}
+ (BABitArray *)bitArray64 {
	return [[[self alloc] initWithLength:64] autorelease];
}
+ (BABitArray *)bitArray512 {
	return [[[self alloc] initWithLength:512] autorelease];
}
+ (BABitArray *)bitArray4096 {
	return [[[self alloc] initWithLength:4096] autorelease];
}

@end


inline static void setBits(unsigned char *byte, NSUInteger start, NSUInteger end) {
	for(NSUInteger i=start; i<=end; ++i)
        *byte |= (1 << i);
}

inline static void clearBits(unsigned char *byte, NSUInteger start, NSUInteger end) {
	for(NSUInteger i=start; i<=end; ++i)
        *byte &= ~(1 << i);
}

// Algorithm found on the web
NSUInteger hammingWeight(unsigned char *bytes, NSRange bitRange) {
	
	NSUInteger first = bitRange.location/bitsInChar;
	NSUInteger start = bitRange.location%bitsInChar;
	NSUInteger last  = (bitRange.location+bitRange.length-1)/bitsInChar;
	NSUInteger end   = (start+bitRange.length-1)%bitsInChar;
	
	NSUInteger odd, even;
	NSUInteger subtotal = 0, total = 0;
	unsigned char firstMask = 0, lastMask = 0, mask=0xFF;
	
    if(first == last) {
        setBits(&firstMask, start, end);
    }
    else {
        if(0 == start)
            firstMask = 0xFF;
        else
            setBits(&firstMask, start, 7);
//        NSLog(@"firstMask = 0x%02X (start %u)", firstMask, start);
        
        if(7 == end)
            lastMask = 0xFF;
        else
            setBits(&lastMask, 0, end);
//        NSLog(@"lastMask = 0x%02X (end %u)", lastMask, end);
    }
	
//	NSLog(@"Counting bits in %u bits", bitRange.length);
	
	for(NSUInteger i=first; i<=last; ++i) {
		
		if(first == i)
			mask = firstMask;
		else if(last == i)
			mask = lastMask;
		else
			mask = 0xFF;
		
		odd  = (bytes[i] & mask)      & 0x55; // 0101 0101 = 0x40 + 0x10 + 0x04 + 0x01
		even = (bytes[i] & mask) >> 1 & 0x55;
		subtotal = odd + even;
		odd  = subtotal      & 0x33; // 0011 0011 - 0x20 + 0x10 + 0x02 + 0x01
		even = subtotal >> 2 & 0x33;
		subtotal = odd + even;
		odd  = subtotal      & 0x0F; // 0000 1111
		even = subtotal >> 4 & 0x0F;
		subtotal = odd + even;		
		total += subtotal;
        
        assert(total <= bitRange.length);
		
//		NSLog(@"subtotal for byte %u (0x%02X): %u; running total: %u", i, bytes[i], subtotal, total);
	}
	
	return total;
}

NSUInteger setRange(unsigned char *bytes, NSRange range, BOOL set) {
	
    if(range.length == 0)
        return 0;
    
	NSUInteger first = range.location/bitsInChar;
	NSUInteger last = (range.location+range.length-1)/bitsInChar;
	NSUInteger start = range.location%bitsInChar;
	NSUInteger end = (start+range.length-1)%bitsInChar;
	unsigned char byteSet = set ? 0xFF : 0;
	
	NSUInteger oldCount = hammingWeight(bytes, range);
    
    // updateBits() is a cover for either setBits() or clearBits(), to reduce the number of if() statements
    // this might defeat the inlining, but I don't know
    void(*updateBits)(unsigned char *, NSUInteger, NSUInteger) = set ? setBits : clearBits;
	
//	NSLog(@"setRange(0x%08X, %@, %@): first %u; last %u; start %u; end %u; old count %u",
//		  bytes, NSStringFromRange(range), set?@"YES":@"NO", first, last, start, end, oldCount);
	
	if (first == last) {
		updateBits(bytes+first, start, end);
	}
	else {
		updateBits(bytes+first, start, bitsInChar-1);
		updateBits(bytes+last, 0, end);		
		if(last - first > 1)
			memset(bytes+first+1, byteSet, last - first - 1);
	}
	
	if(set)
		return range.length - oldCount;
	else
		return oldCount;
}

NSInteger copyBits(unsigned char *bytes, BOOL *bits, NSRange range, BOOL write) {

    if(range.length == 0)
        return 0;
    
	NSUInteger first = range.location/bitsInChar;
	NSUInteger last = (range.location+range.length-1)/bitsInChar;
	NSUInteger start = range.location%bitsInChar;
    NSUInteger k = 0;
    
    NSInteger oldCount = 0, difference = 0;
    
    if(write)
        oldCount = hammingWeight(bytes, range);

    for (NSUInteger i=first; i<=last; ++i) {
        
        NSUInteger end = i == last ? (start+range.length-1)%bitsInChar : bitsInChar - 1;
        char c = bytes[i];
        
        for (NSUInteger j=start; j<=end; ++j) {
            assert(k<range.length);
            if(write) {
                if(bits[k])
                    c |= 1<<j;
                else
                    c &= ~(1<<j);
            }
            else {
                bits[k] = ((c & 1<<j) != 0);
            }
            ++k;
        }
        if(write)
            bytes[i] = c;
    }
    
    if(write) {
        NSInteger newCount = hammingWeight(bytes, range);
        difference = newCount - oldCount;
    }
    
    return difference;
}
