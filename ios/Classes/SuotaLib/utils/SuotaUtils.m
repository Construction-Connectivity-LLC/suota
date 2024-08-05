/*
 *******************************************************************************
 *
 * Copyright (C) 2019-2020 Dialog Semiconductor.
 * This computer program includes Confidential, Proprietary Information
 * of Dialog Semiconductor. All Rights Reserved.
 *
 *******************************************************************************
 */

#import "SuotaUtils.h"

@implementation SuotaUtils

+ (NSString*) hexArray:(NSData*)v uppercase:(BOOL)uppercase brackets:(BOOL)brackets {
    if (!v)
        return brackets ? @"[]" : @"";
    NSString* hexFormat = uppercase ? @"%02X " : @"%02x ";
    NSMutableString* buffer = [NSMutableString stringWithCapacity:v.length * 3 + 3];
    if (brackets)
        [buffer appendString:@"[ "];
    const uint8_t* b = v.bytes;
    for (int i = 0; i < v.length; ++i) {
        [buffer appendFormat:hexFormat, b[i]];
    }
    if (brackets)
        [buffer appendString:@"]"];
    return buffer;
}

+ (NSString*) hexArray:(NSData*)v {
    return [self hexArray:v uppercase:false brackets:true];
}

@end

@implementation SuotaByteBuffer

- (instancetype) init {
    self = [super init];
    if (!self)
        return nil;
    self.order = SuotaByteBufferBigEndian;
    self.position = 0;
    return self;
}

- (instancetype) initWithCapacity:(int)capacity {
    self = [self init];
    if (!self)
        return nil;
    self.data = [NSMutableData dataWithCapacity:capacity];
    return self;
}

- (instancetype) initWithBuffer:(NSData*)data {
    self = [self init];
    if (!self)
        return nil;
    self.data = data;
    return self;
}

+ (instancetype) allocate:(int)capacity {
    return [(SuotaByteBuffer*)[self alloc] initWithCapacity:capacity];
}

+ (instancetype) allocate:(int)capacity order:(int)order {
    SuotaByteBuffer* buffer = [self allocate:capacity];
    buffer.order = order;
    return buffer;
}

+ (instancetype) wrap:(NSData*)data {
    return [[self alloc] initWithBuffer:data];
}

+ (instancetype) wrap:(NSData*)data order:(int)order {
    SuotaByteBuffer* buffer = [self wrap:data];
    buffer.order = order;
    return buffer;
}

+ (instancetype) wrap:(NSData*)data offset:(int)offset length:(int)length order:(int)order {
    return [self wrap:[data subdataWithRange:NSMakeRange(offset ,length)] order:order];
}

- (void) put:(uint8_t)v {
    [(NSMutableData*)self.data appendBytes:&v length:1];
}

- (void) putShort:(uint16_t)v {
    v = self.order == SuotaByteBufferBigEndian ? CFSwapInt16HostToBig(v) : CFSwapInt16HostToLittle(v);
    [(NSMutableData*)self.data appendBytes:&v length:2];
}

- (void) putInt:(uint32_t)v {
    v = self.order == SuotaByteBufferBigEndian ? CFSwapInt32HostToBig(v) : CFSwapInt32HostToLittle(v);
    [(NSMutableData*)self.data appendBytes:&v length:4];
}

- (void) putLong:(uint64_t)v {
    v = self.order == SuotaByteBufferBigEndian ? CFSwapInt64HostToBig(v) : CFSwapInt64HostToLittle(v);
    [(NSMutableData*)self.data appendBytes:&v length:8];
}

- (void) putData:(NSData*)v {
    [(NSMutableData*)self.data appendData:v];
}

- (void) put:(const uint8_t*)v length:(int)length {
    [(NSMutableData*)self.data appendBytes:v length:length];
}

- (uint8_t) get {
    uint8_t v = [self get:self.position];
    self.position += 1;
    return v;
}

- (uint16_t) getShort {
    uint16_t v = [self getShort:self.position];
    self.position += 2;
    return v;
}

- (uint32_t) getInt {
    uint32_t v = [self getInt:self.position];
    self.position += 4;
    return v;
}

- (uint64_t) getLong {
    uint64_t v = [self getLong:self.position];
    self.position += 8;
    return v;
}

- (NSData*) getData:(int)length {
    NSData* data = [self getData:self.position length:length];
    self.position += length;
    return data;
}

- (uint8_t) get:(int)position {
    [self checkRange:position length:1];
    return *((uint8_t*)self.data.bytes + position);
}

- (uint16_t) getShort:(int)position {
    [self checkRange:position length:2];
    uint16_t v = *(uint16_t*)((uint8_t*)self.data.bytes + position);
    return self.order == SuotaByteBufferBigEndian ? CFSwapInt16BigToHost(v) : CFSwapInt16LittleToHost(v);
}

- (uint32_t) getInt:(int)position {
    [self checkRange:position length:4];
    uint32_t v = *(uint32_t*)((uint8_t*)self.data.bytes + position);
    return self.order == SuotaByteBufferBigEndian ? CFSwapInt32BigToHost(v) : CFSwapInt32LittleToHost(v);
}

- (uint64_t) getLong:(int)position {
    [self checkRange:position length:8];
    uint64_t v = *(uint64_t*)((uint8_t*)self.data.bytes + position);
    return self.order == SuotaByteBufferBigEndian ? CFSwapInt64BigToHost(v) : CFSwapInt64LittleToHost(v);
}

- (NSData*) getData:(int)position length:(int)length {
    [self checkRange:position length:length];
    return [self.data subdataWithRange:NSMakeRange(position, length)];
}

- (int) remaining {
    return (int)self.data.length - self.position;
}

- (BOOL) hasRemaining {
    return self.position < self.data.length;
}

- (void) checkRange:(int)position length:(int)length {
    if (position + length > self.data.length)
        @throw [NSException exceptionWithName:NSRangeException reason:@"SuotaByteBuffer range error" userInfo:nil];
}

@end
