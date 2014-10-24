 //
//  BABitArray.m
//
//  Created by Brent Gulanowski on 09-09-27.
//  Copyright 2009 Bored Astronaut. All rights reserved.
//

#import <BAFoundation/BABitArray.h>

#import <BAFoundation/BAFunctions.h>
#import <BAFoundation/NSData+GZip.h>


// Set/clear a range of bit positions in a single byte
static void setBits(unsigned char *byte, NSUInteger start, NSUInteger end);
static void clearBits(unsigned char *byte, NSUInteger start, NSUInteger end);

// These functions refer to a range of bits starting in the byte at the address provided
// Count the number of set bits
NSUInteger hammingWeight(unsigned char *bytes, NSRange range);

// Copy bits from, or to, the provided array of BOOLs
NSInteger copyBits(unsigned char *bytes, BOOL *bits, NSRange range, BOOL write, BOOL reverse);

// Set or clear bits
NSInteger setRange(unsigned char *bytes, NSRange range, BOOL set);


@interface BABitArray ()

@property (readwrite) NSUInteger count;

@end


@implementation BABitArray

@synthesize length, count, enableArchiveCompression;
@synthesize size;


NSUInteger bitsInChar = NSNotFound;
NSUInteger maxBitOffset;


static inline BOOL setBit(unsigned char *buffer, NSUInteger index) {
    
	NSUInteger byte = index/bitsInChar;
	NSUInteger bit = index%bitsInChar;
#if SEQUENTIAL_BIT_ORDER
	unsigned char mask = (1 << (maxBitOffset - bit));
#else
	unsigned char mask = (1 << bit);
#endif
	
    BOOL wasSet = buffer[byte] & mask;
    
    if(!wasSet)
		buffer[byte] |= mask;
    
    return !wasSet;
}

static inline NSUInteger findNextSetBitInByte(unsigned char byte, NSUInteger start) {
	assert(start < bitsInChar);
	NSUInteger b = start;
	
#if SEQUENTIAL_BIT_ORDER
	while(b<bitsInChar && !(byte>>(maxBitOffset-b)&1)) b++;
#else
	while(b<bitsInChar && !(byte>>b&1)) b++;
#endif
	return b >= bitsInChar ? NSNotFound : b;
}

static inline NSUInteger findPrevSetBitInByte(unsigned char byte, NSUInteger start) {
	assert(start < bitsInChar);
	NSUInteger b = start;
#if SEQUENTIAL_BIT_ORDER
	while(b>0 && !(byte>>(maxBitOffset - b)&1)) b--;
#else
	while(b>0 && !(byte>>b&1)) b--;
#endif
	return b >= bitsInChar ? NSNotFound : b;
}

static inline NSUInteger findNextClearBitInByte(unsigned char byte, NSUInteger start) {
	assert(start < bitsInChar);
	NSUInteger b = start;
#if SEQUENTIAL_BIT_ORDER
    while(b<bitsInChar && !(~byte>>(maxBitOffset-b)&1)) b++;
#else
    while(b<bitsInChar && !(~byte>>b&1)) b++;
#endif
	return b >= bitsInChar ? NSNotFound : b;
}

static inline NSUInteger findPrevClearBitInByte(unsigned char byte, NSUInteger start) {
	assert(start < bitsInChar);
	NSUInteger b = start;
#if SEQUENTIAL_BIT_ORDER
    while(b>0 && !(~byte>>(maxBitOffset-b)&1)) b--;
#else
	while(b>0 && !(~byte>>b&1)) b--;
#endif
	return b >= bitsInChar ? NSNotFound : b;
}

static inline BOOL clrBit(unsigned char *buffer, NSUInteger index) {
    
	NSUInteger byte = index/bitsInChar;
	NSUInteger bit = index%bitsInChar;
#if SEQUENTIAL_BIT_ORDER
	unsigned char mask = (1 << (maxBitOffset - bit));
#else
	unsigned char mask = (1 << bit);
#endif
	
    BOOL wasSet = buffer[byte] & mask;
    
	if(wasSet)
		buffer[byte] &= ~mask;
	
    return wasSet;
}

// These macros are intended only for use within this file, as they refer to ivars directly
#if SEQUENTIAL_BIT_ORDER
#define GET_BIT(_index_) ((buffer[((_index_)/bitsInChar)] & (1 << (maxBitOffset - ((_index_)%bitsInChar)))) != 0)
#else
#define GET_BIT(_index_) ((buffer[((_index_)/bitsInChar)] & (1 << ((_index_)%bitsInChar))) != 0)
#endif
#define SET_BIT(_index_) do { if(setBit(buffer, _index_)) ++count; }while(0)
#define CLR_BIT(_index_) do { if(clrBit(buffer, _index_)) --count; }while(0)

#define SET_OTHER_BIT(_bitArray_, _index_) do { if(setBit((_bitArray_)->buffer, _index_)) ++(_bitArray_)->count; }while(0)


#pragma mark - Accessors
- (NSData *)bufferData {
    return [NSData dataWithBytes:buffer length:bufferLength];
}


#pragma mark - NSObject
+ (void)initialize {
	if(NSNotFound == bitsInChar) {
		bitsInChar = sizeof(char)*8;
		maxBitOffset = bitsInChar - 1;
//		NSLog(@"bits in char: %u", bitsInChar);
	}
}

- (id)init {
	return [self initWithLength:0];
}

- (void)dealloc {
	if (length > 0)
		free(buffer);
    [size release], size = nil;
	[super dealloc];
}

- (NSString *)description {
        
    NSString *state;
    
    if(count == 0)
        state = @"empty";
    else if(count == length)
        state = @"full";
    else {
        
        long firstSet = [self firstSetBit];
        long firstClr = [self firstClearBit];
        long lastSet = [self lastSetBit];
        long lastClr = [self lastClearBit];
        
        if(firstSet == NSNotFound) firstSet = -1;
        if(firstClr == NSNotFound) firstClr = -1;
        if(lastSet == NSNotFound) lastSet = -1;
        if(lastClr == NSNotFound) lastClr = -1;
        
        state = [NSString stringWithFormat:@"set: %ld-%ld; clear: %ld-%ld", firstSet, lastSet, firstClr, lastClr];
    }
    
	return [NSString stringWithFormat:@"%@ length:%lu count:%lu; state: %@",
			[super description], (unsigned long)length, (unsigned long)count, state];
}

- (BOOL)isEqual:(id)object {
	return [object isKindOfClass:[self class]] && [self isEqualToBitArray:object];
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
    [aCoder encodeObject:size forKey:@"size"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    NSData *data = [aDecoder decodeObjectForKey:@"data"] ?: [[aDecoder decodeObjectForKey:@"gzippedData"] gzipInflate];
    self = [self initWithData:data length:[aDecoder decodeIntegerForKey:@"length"]];
    if(self) {
        enableArchiveCompression = [aDecoder decodeBoolForKey:@"compressed"];
        size = [[aDecoder decodeObjectForKey:@"size"] retain];
		size2d = size.size2d;
        
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

- (BOOL)isEqualToBitArray:(BABitArray *)other {
	
    if((size != other->size) && ![size isEqualToSampleArray:other->size])
        return NO;
    
	return (count == other->count &&
			length == other->length &&
			bufferLength == other->bufferLength &&
			!memcmp(buffer, other->buffer, bufferLength));
}

- (BOOL)bit:(NSUInteger)index {
	if(index > length)
		[NSException raise:NSInvalidArgumentException format:@"index beyond bounds: %lu", (unsigned long)index];
		
//	NSLog(@"Checking bit %u in byte %u (0x%02X): 0x%02X", bit, byte, buffer[byte], (buffer[byte] & (1 << bit)));
//	return (BOOL)((buffer[(index/bitsInChar)] & (1 << (index%bitsInChar))) != 0);
    return GET_BIT(index);
}

- (void)setBit:(NSUInteger)index {
    if(count == length)
        return;
	if(index > length)
        [NSException raise:NSInvalidArgumentException format:@"index beyond bounds: %lu", (unsigned long)index];
    SET_BIT(index);
}

- (void)setRange:(NSRange)bitRange {
    if(count == length)
        return;
    NSUInteger maxIndex = bitRange.location+bitRange.length-1;
	if(maxIndex >= length)
		[NSException raise:NSInvalidArgumentException format:@"index beyond bounds: %lu", (unsigned long)maxIndex];
	count += setRange(buffer, bitRange, YES);
    NSAssert([self checkCount], @"Count incorrect after setting range");
}

- (void)setAll {
    if(count == length)
        return;
	memset(buffer, 0xff, bufferLength);
	count = length;
}

- (void)clearBit:(NSUInteger)index {
    if(count == 0)
        return;
	if(index > length)
		[NSException raise:NSInvalidArgumentException format:@"index beyond bounds: %lu", (unsigned long)index];
    CLR_BIT(index);
}

- (void)clearRange:(NSRange)bitRange {
    if(count == 0)
        return;
    NSUInteger maxIndex = bitRange.location+bitRange.length-1;
	if(maxIndex >= length)
		[NSException raise:NSInvalidArgumentException format:@"index beyond bounds: %lu", (unsigned long)maxIndex];
	count += setRange(buffer, bitRange, NO);
    NSAssert([self checkCount], @"Count incorrect after setting range");
}

- (void)clearAll {
    if(count == 0)
        return;
	memset(buffer, 0, bufferLength);
	count = 0;
}

- (NSUInteger)first:(unsigned char *)p {
    
	while(!*p && p<buffer+bufferLength-1) p++;
    
    if(p-buffer>=bufferLength)
        return NSNotFound;

	return (p-buffer)*bitsInChar + findNextSetBitInByte(*p, 0);
}

- (NSUInteger)firstSetBit {
    if(count == 0)
        return NSNotFound;
    if(count == length)
        return 0;
    return [self first:buffer];
}

- (NSUInteger)lastSetBit {
    
    if(count == 0)
        return NSNotFound;
    if(count == length)
        return length-1;

	unsigned char *p = buffer+bufferLength-1;

	while(!*p && p>=buffer) p--;
    
    if(p < buffer)
        return NSNotFound;

	return (p-buffer)*bitsInChar + findPrevSetBitInByte(*p, maxBitOffset);
}

- (NSUInteger)indexOfNthSetBit:(NSUInteger)n {

    NSUInteger index = [self firstSetBit];
    
    for (NSUInteger i=0; i<n && index != NSNotFound; ++i)
        index = [self nextAfter:index];
    
    return index;
}

- (NSUInteger)readBits:(BOOL *)bits range:(NSRange)range {
    NSUInteger maxIndex = range.location+range.length-1;
	if(maxIndex >= length)
		[NSException raise:NSInvalidArgumentException format:@"index beyond bounds: %lu", (unsigned long)maxIndex];
    return copyBits(buffer, bits, range, NO, NO);
}

- (NSUInteger)writeBits:(BOOL *const)bits range:(NSRange)range {
    NSUInteger maxIndex = range.location+range.length-1;
	if(maxIndex >= length)
		[NSException raise:NSInvalidArgumentException format:@"index beyond bounds: %lu", (unsigned long)maxIndex];
    NSUInteger diff = copyBits(buffer, bits, range, YES, NO);
    count+=diff;
    return diff;
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
    
	NSUInteger firstByte = bitRange.location/bitsInChar;
	NSUInteger lastByte = (bitRange.location+bitRange.length-1)/bitsInChar;
	NSUInteger firstBit = bitRange.location%bitsInChar;
    
    for (NSUInteger i=firstByte; i<lastByte; ++i) {
#if SEQUENTIAL_BIT_ORDER
        pair.c8[0] = buffer[i+1];
        pair.c8[1] = buffer[i];
        pair.c16 <<= firstBit;
        subBuffer[i-firstByte] = pair.c8[1];
#else
        pair.c8[0] = buffer[i];
        pair.c8[1] = buffer[i+1];
        pair.c16 >>= firstBit;
        subBuffer[i-firstByte] = pair.c8[0];
#endif
    }
    
	NSUInteger lastBit = bitRange.length%bitsInChar;
	
    if(bytesLength*bitsInChar > bitRange.length)
        clearBits(subBuffer+bytesLength-1, lastBit, bitsInChar-1);
    
    return [NSData dataWithBytesNoCopy:subBuffer length:bytesLength freeWhenDone:YES];
}

- (NSUInteger)firstClearBit {
    
    if(count == 0)
        return 0;
    if(count == length)
        return NSNotFound;
	
	unsigned char *p = buffer;
	while(!(unsigned char)~*p && p<buffer+bufferLength-1) p++;

    if(p-buffer>=bufferLength)
        return NSNotFound;
    
	return (p-buffer)*bitsInChar + findNextClearBitInByte(*p, 0);
}

- (NSUInteger)lastClearBit {
    
    if(count == 0)
        return length-1;
    if(count == length)
        return NSNotFound;
	
	unsigned char *p = buffer+bufferLength-1;
    while(!(unsigned char)~*p && p-->=buffer);
    
    if(p < buffer)
        return NSNotFound;
    
	return (p-buffer)*bitsInChar + findPrevClearBitInByte(*p, maxBitOffset);
}

- (NSUInteger)indexOfNthClearBit:(NSUInteger)n {
    
    if(count == 0)
        return n;
    else if(n == length-count)
        return [self lastClearBit];
    else if(n > length-count)
        return NSNotFound;

    NSUInteger first = [self firstClearBit];
    
    if(n == 0)
        return first;
    
    // TODO: if n > (length-count)/2, work backwards from end
    
    NSUInteger nextSet = [self nextAfter:first];
    NSUInteger prevSet;
    NSUInteger block;
    NSUInteger total = 1;

    while (nextSet < length) {
        prevSet = nextSet;
        nextSet = [self nextAfter:prevSet];
        block = nextSet - prevSet - 1;
        if(n - total >= block)
            return nextSet - 1 - (block - (n - total));
        total += block;
    }
    
    return NSNotFound;
}

- (NSUInteger)nextAfter:(NSUInteger)prev {
    
	unsigned char *p = buffer + prev/bitsInChar;
	NSUInteger b = prev%bitsInChar+1;
	
	if(b < bitsInChar)
		b = findNextSetBitInByte(*p, b);
	
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

- (id)initWithLength:(NSUInteger)bits size:(BASampleArray *)vector {
	if(bits > 256*256*256)
		[NSException raise:NSInvalidArgumentException format:@"Requested unreasonable length for bit array (%lu)", (unsigned long)bits];
	self = [super init];
	if(self) {
		length = bits; // never changes
        size = [vector copy]; // never changes
		size2d = size.size2d;
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

- (id)initWithLength:(NSUInteger)bits {
    return [self initWithLength:bits size:nil];
}

- (BOOL)checkCount {
	return hammingWeight(buffer, NSMakeRange(0, length)) == count;
}

- (void)refreshCount {
	count = hammingWeight(buffer, NSMakeRange(0, length));
}

- (NSString *)stringForRange:(NSRange)range {
    
    char * bytes = calloc(sizeof(char), range.length+1);
    
    NSAssert(bytes, @"memory error");
    
    bytes[range.length] = '\0';
    
    for(NSUInteger i=0; i<range.length; ++i)
        bytes[i] = GET_BIT(range.location+i) ? 'S' : '_';
    
    NSString *result = [NSString stringWithCString:bytes encoding:NSASCIIStringEncoding];
    
    free(bytes);
    
    return result;
}


#pragma mark Factories
- (BABitArray *)reverseBitArray {
    
    const size_t copyBatchSize = 256;
    
    BABitArray *reverse = [BABitArray bitArrayWithLength:length size:[[size copy] autorelease]];
    NSUInteger copyCount = MIN(copyBatchSize, length);
    NSRange sourceRange = NSMakeRange(0, copyCount);
    NSRange destRange = NSMakeRange(length-copyCount, copyCount);

    BOOL *bits = malloc(copyBatchSize*sizeof(BOOL));

    while (sourceRange.location < length-1) {

        copyBits(buffer, bits, sourceRange, NO, YES);
        copyBits(reverse->buffer, bits, destRange, YES, NO);

        sourceRange.location += copyCount;

        copyCount = MIN(copyBatchSize, length-sourceRange.location);
        destRange.location -= copyCount;

        sourceRange.length = copyCount;
        destRange.length = copyCount;
    }
    
    free(bits);
    
    return reverse;
}

+ (BABitArray *)bitArrayWithLength:(NSUInteger)bits size:(BASampleArray *)vector {
	return [[[self alloc] initWithLength:bits size:vector] autorelease];
}
+ (BABitArray *)bitArrayWithLength:(NSUInteger)bits {
	return [[[self alloc] initWithLength:bits size:nil] autorelease];
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
	for(NSUInteger i=start; i<=end; ++i) {
#if SEQUENTIAL_BIT_ORDER
        *byte |= (1 << (maxBitOffset - i));
#else
        *byte |= (1 << i);
#endif
	}
}

inline static void clearBits(unsigned char *byte, NSUInteger start, NSUInteger end) {
	for(NSUInteger i=start; i<=end; ++i) {
#if SEQUENTIAL_BIT_ORDER
        *byte &= ~(1 << (maxBitOffset - i));
#else
        *byte &= ~(1 << i);
#endif
	}
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
        
        if(7 == end)
            lastMask = 0xFF;
        else
            setBits(&lastMask, 0, end);
    }
		
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
    }
	
	return total;
}

NSInteger setRange(unsigned char *bytes, NSRange range, BOOL set) {
	
    if(range.length == 0)
        return 0;
    
	NSUInteger first = range.location/bitsInChar;
	NSUInteger last = (range.location+range.length-1)/bitsInChar;
	NSUInteger start = range.location%bitsInChar;
	NSUInteger end = (start+range.length-1)%bitsInChar;
	unsigned char byteSet = set ? 0xFF : 0;
	
	NSInteger oldCount = hammingWeight(bytes, range);
    
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
		return (NSInteger)range.length - oldCount;
	else
		return -oldCount;
}


NSInteger copyBits(unsigned char *bytes, BOOL *bits, NSRange range, BOOL write, BOOL reverse) {

    if(range.length == 0)
        return 0;
    
    NSUInteger frst = range.location;
    NSUInteger last = range.location+range.length-1;
	NSUInteger frstByte = frst/bitsInChar;
	NSUInteger lastByte = last/bitsInChar;
    NSUInteger k = reverse ? range.length-1 : 0;
    NSUInteger inc = reverse ? -1 : 1;
    
    NSInteger oldCount = hammingWeight(bytes, range);
    
    for (NSUInteger i=frstByte; i<=lastByte; ++i) {
        
        NSUInteger frstBit = i == frstByte ? frst%bitsInChar : 0;
        NSUInteger lastBit = i == lastByte ? last%bitsInChar : bitsInChar - 1;
        char c = bytes[i];
        
        for (NSUInteger j=frstBit; j<=lastBit; ++j) {
            assert(k<range.length);
#if SEQUENTIAL_BIT_ORDER
			char mask = 1 << (maxBitOffset - j);
#else
			char mask = 1 << j;
#endif
            if(write) {
                if(bits[k])
                    c |= mask;
                else
                    c &= ~mask;
            }
            else {
                bits[k] = ((c & mask) != 0);
            }
            k+=inc;
        }
        if(write)
            bytes[i] = c;
    }
    
    NSUInteger result;
    
    if(write) {
        NSInteger newCount = hammingWeight(bytes, range);
        assert(newCount == countBits(bits, range.length));
        result = newCount - oldCount;
    }
    else {
        result = oldCount;
        assert(oldCount == countBits(bits, range.length));
    }

    return result;
}


@implementation BABitArray (SpatialStorage)

@dynamic count;
@dynamic length;

#define BIT_ARRAY_SIZE_ASSERT() NSAssert(size != nil, @"Cannot perform spatial calculations without size")

- (BOOL)bitAtX:(NSUInteger)x y:(NSUInteger)y {
    BIT_ARRAY_SIZE_ASSERT();
    return GET_BIT(x + y*(NSUInteger)size2d.width);
}

- (void)setBitAtX:(NSUInteger)x y:(NSUInteger)y {
    BIT_ARRAY_SIZE_ASSERT();
    SET_BIT(x + y*(NSUInteger)size2d.width);
}

- (void)clearBitAtX:(NSUInteger)x y:(NSUInteger)y {
    BIT_ARRAY_SIZE_ASSERT();
    SET_BIT(x + y*(NSUInteger)size2d.width);
}


- (BOOL)bitAtX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z {
    BIT_ARRAY_SIZE_ASSERT();
    NSUInteger dims[3];
    [size size3d:dims];
    return GET_BIT(x + y*dims[0] + z*dims[1]*dims[0]);
}

- (void)setBitAtX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z {
    BIT_ARRAY_SIZE_ASSERT();
    NSUInteger dims[3];
    [size size3d:dims];
    SET_BIT(x + y*dims[0] + z*dims[1]*dims[0]);
}

- (void)clearBitAtX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z {
    BIT_ARRAY_SIZE_ASSERT();
    NSUInteger dims[3];
    [size size3d:dims];
    CLR_BIT(x + y*dims[0] + z*dims[1]*dims[0]);
}


#define BIT_ARRAY_RECT_ASSERT() NSAssert(CGRectGetMinX(rect) >= 0 && CGRectGetMinY(rect) >= 0 && CGRectGetMaxX(rect) <= size2d.width && CGRectGetMaxY(rect) <= size2d.height, @"error")

- (void)updateRect:(CGRect)rect set:(BOOL)set {
    
    BIT_ARRAY_SIZE_ASSERT();
    BIT_ARRAY_RECT_ASSERT();
    
    NSRange range = NSMakeRange(rect.origin.x+size2d.width*rect.origin.y, rect.size.width);
    NSInteger delta = 0;
    
    NSAssert([self checkCount], @"count incorrect");
    
    for (NSUInteger i=0; i<rect.size.height; ++i) {
        delta += setRange(buffer, range, set);
        range.location += size2d.width;
    }
    
    count += delta;
    
    NSAssert([self checkCount], @"count incorrect");
}

- (void)setRect:(CGRect)rect {
    [self updateRect:rect set:YES];
}

- (void)clearRect:(CGRect)rect {
    [self updateRect:rect set:NO];
}

- (void)writeRect:(CGRect)rect fromArray:(BABitArray *)bitArray offset:(CGPoint)origin {
    
    CGSize sourceSize = bitArray.size.size2d;
    
    BIT_ARRAY_SIZE_ASSERT();
    BIT_ARRAY_RECT_ASSERT();

    NSRange sourceRange = NSMakeRange(origin.x+sourceSize.width*origin.y, rect.size.width);
    NSRange destRange = NSMakeRange(rect.origin.x+size2d.width*rect.origin.y, rect.size.width);
    
    // TODO: Replace with more effective implementation
    BOOL *bits = malloc(rect.size.width*sizeof(BOOL));
    
    for (NSUInteger i=0; i<rect.size.height; ++i) {
        [bitArray readBits:bits range:sourceRange];
        sourceRange.location += sourceSize.width;
        [self writeBits:bits range:destRange];
        destRange.location += size2d.width;
    }
    
    free(bits);
}

- (void)writeRect:(CGRect)rect fromArray:(BABitArray *)bitArray {
    [self writeRect:rect fromArray:bitArray offset:CGPointZero];
}

- (id<BABitArray2D>)subArrayWithRect:(CGRect)rect {
    
    BABitArray *result = [BABitArray bitArrayWithLength:rect.size.width*rect.size.height size:[BASampleArray sampleArrayForSize2d:rect.size]];
    CGPoint origin = rect.origin;
    
    rect.origin = CGPointZero;
    
    [result writeRect:rect fromArray:self offset:origin];
    
    return result;
}

- (id)initWithBitArray:(id<BABitArray2D>)otherArray rect:(CGRect)rect {
    self = [self initWithLength:rect.size.width*rect.size.height size:[BASampleArray sampleArrayForSize2d:rect.size]];
    if(self) {

        CGPoint origin = rect.origin;
        
        rect.origin = CGPointZero;
        
        [self writeRect:rect fromArray:otherArray offset:origin];
    }
    return self;
}

- (NSArray *)rowStringsForRect:(CGRect)rect {
    
    NSMutableArray *rows = [NSMutableArray array];
	
    if(CGRectEqualToRect(rect, CGRectZero))
        rect.size = size2d;
    
    NSRange range = NSMakeRange(rect.origin.x+size2d.width*rect.origin.y, rect.size.width);
    NSUInteger maxY = rect.origin.y + rect.size.height;
    
    for (NSUInteger i=rect.origin.y; i<maxY; ++i) {
        [rows insertObject:[self stringForRange:range] atIndex:0];
        range.location += size2d.width;
    }
    
    return [[rows copy] autorelease];
}

- (NSString *)stringForRect:(CGRect)rect {
    return [[self rowStringsForRect:rect] componentsJoinedByString:@"\n"];
}

- (NSString *)stringForRect {
    return [[self rowStringsForRect:CGRectZero] componentsJoinedByString:@"\n"];
}

- (id)initWithSize:(CGSize)initSize {
    return [self initWithLength:initSize.width*initSize.height size:[BASampleArray sampleArrayForSize2d:initSize]];
}

- (BABitArray *)bitArrayByFlippingColumns {
    
    if(count == 0 || count == length)
        return [[self copy] autorelease];
    
    BABitArray *copy = [BABitArray bitArrayWithLength:length size:[[size copy] autorelease]];
    
    NSUInteger width = size2d.width;
    NSUInteger height = size2d.height;
    
    for (NSUInteger i=0; i<height; ++i) {
        for (NSUInteger j=0; j<width; ++j) {
            if(GET_BIT(j + i*width))
                SET_OTHER_BIT(copy, width-j-1 + i*width);
        }
    }
    
    return copy;
}

- (BABitArray *)bitArrayByFlippingRowsReverse:(BOOL)reverse {
    
    if(count == 0 || count == length)
        return [[self copy] autorelease];
    
    BABitArray *copy = [BABitArray bitArrayWithLength:length size:[[size copy] autorelease]];
    NSUInteger width = size2d.width;
    NSUInteger height = size2d.height;
    
    BOOL *bits = malloc(sizeof(BOOL)*width);
    
    NSRange source = NSMakeRange(0, width);
    NSRange dest = NSMakeRange((height-1)*width, width);

    for (NSUInteger i=0; i<height; ++i) {
        copyBits(buffer, bits, source, NO, NO);
        source.location += width;
        copyBits(copy->buffer, bits, dest, YES, reverse);
        dest.location -= width;
    }
    
    [copy refreshCount];
    
    free(bits);
    
    return copy;
}

- (BABitArray *)bitArrayByFlippingRows {
    return [self bitArrayByFlippingRowsReverse:NO];
}

- (BABitArray *)bitArrayByRotating:(NSInteger)quarters {
    
    quarters = quarters%4;
    
    if(quarters < 0)
        quarters += 4;
    
    BABitArray *copy = nil;
    NSUInteger width = size2d.width;
    NSUInteger height = size2d.height;
    
    switch (quarters) {
            
        case 0:
            copy = [[self copy] autorelease];
            break;

        case 1:
            copy = [BABitArray bitArrayWithLength:length size:nil];
            // Rotate 90 CCW around origin, then translate by x+width
            // (x,y) -> (-y, x) -> (w+x, y) = (w+(-y), x) = (w-y, x)
            // x2 = -y, x3 = w-x2 = w - (-y) = w-y
            // y2 = x,  y3 = y2 = x
            // index = x3 + w*y3 = (w-y) + w*x
            // w is actually width-1 for indexed storage
            for (NSUInteger i=0; i<height; ++i) {
                for (NSUInteger j=0; j<width; ++j) {
                    if(GET_BIT(j + i*width))
                        SET_OTHER_BIT(copy, (width-1-i) + j*width);
                }
            }

            break;
            
        case 2: // (x, y) -> (width-x-1, height-y-1)
            copy = [self bitArrayByFlippingRowsReverse:YES];
            break;
            
        case 3:
        default:
            copy = [BABitArray bitArrayWithLength:length size:nil];
            // Rotate 90 CW around origin, then translate by y+height
            // (x,y) -> (y, -x) -> (x, h+y) = (y, h+(-x)) = (y, h-x)
            // x2 = y, x3 = x2 = y
            // y2 = -x, y3 = h+y2 = h+(-x) = h-x
            // index = x3 + w*y3 = y + w*(h-x)
            // wi is actually width-1 for indexed storage
            for (NSUInteger i=0; i<height; ++i) {
                for (NSUInteger j=0; j<width; ++j) {
                    if(GET_BIT(j + i*width))
                        SET_OTHER_BIT(copy, i + (height-1-j)*width);
                }
            }

            break;
    }
    
    if(quarters == 1 || quarters == 3) {
        // swap height and width in size
        copy->size = [[BASampleArray sampleArrayForSize2d:CGSizeMake(height, width)] retain];
        [copy refreshCount];
    }
    
    return copy;
}

+ (BABitArray *)bitArrayWithSize:(CGSize)initSize {
    return [[(BABitArray *)[self alloc] initWithSize:initSize] autorelease];
}

@end


@implementation BASampleArray (BABitArraySupport)

- (CGSize)size2d {
    CGSize result;
    [self readSamples:(UInt8 *)&result range:NSMakeRange(0, 2)];
    return result;
}

- (void)size3d:(NSUInteger*)size {
    [self readSamples:(UInt8 *)&size range:NSMakeRange(0, 3)];
}

+ (BASampleArray *)sampleArrayForSize2d:(CGSize)size {
    BASampleArray *result = [[[BASampleArray alloc] initWithPower:1 order:2 size:sizeof(CGFloat)/sizeof(UInt8)] autorelease];
    [result writeSamples:(UInt8 *)&size range:NSMakeRange(0, 2)];
    return result;
}

+ (BASampleArray *)sampleArrayForSize3d:(NSUInteger *)size {
    BASampleArray *result = [[[BASampleArray alloc] initWithPower:1 order:3 size:sizeof(NSUInteger)/sizeof(UInt8)] autorelease];
    [result writeSamples:(UInt8 *)&size range:NSMakeRange(0, 3)];
    return result;
}

@end