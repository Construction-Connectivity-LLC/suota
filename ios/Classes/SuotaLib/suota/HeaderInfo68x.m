/*
 *******************************************************************************
 *
 * Copyright (C) 2019-2020 Dialog Semiconductor.
 * This computer program includes Confidential, Proprietary Information
 * of Dialog Semiconductor. All Rights Reserved.
 *
 *******************************************************************************
 */

#import "HeaderInfo68x.h"
#import "SuotaUtils.h"

#define HEADER_68_X_SIGNATURE 0x7061
#define HEADER_68_X_HEADER_SIZE 36

#define HEADER_68_X_OFFSET_FLAGS 2
#define HEADER_68_X_OFFSET_PAYLOAD_SIZE 4
#define HEADER_68_X_OFFSET_PAYLOAD_CRC 8
#define HEADER_68_X_OFFSET_VERSION 12
#define HEADER_68_X_VERSION_LENGTH 16
#define HEADER_68_X_OFFSET_TIMESTAMP 28
#define HEADER_68_X_OFFSET_EXEC_LOCATION 32


@implementation HeaderInfo68x

static NSString* const HEADER_68_X_TYPE = @"68x";

+ (NSString*) TYPE {
    return HEADER_68_X_TYPE;
}

+ (int) SIGNATURE {
    return HEADER_68_X_SIGNATURE;
}

+ (int) HEADER_SIZE {
    return HEADER_68_X_HEADER_SIZE;
}

- (instancetype) initWithHeader:(NSData*)header totalBytes:(uint64_t)totalBytes {
    self = [super initWithOffsetPayloadSize:HEADER_68_X_OFFSET_PAYLOAD_SIZE offsetPayloadCrc:HEADER_68_X_OFFSET_PAYLOAD_CRC offsetVersion:HEADER_68_X_OFFSET_VERSION versionLength:HEADER_68_X_VERSION_LENGTH offsetTimestamp:HEADER_68_X_OFFSET_TIMESTAMP header:header totalBytes:totalBytes];
    if (!self)
        return nil;
    [self initializeTypeSpecific];
    return self;
}

- (instancetype) initWithRawBuffer:(NSData*)rawBuffer {
    self = [super initWithOffsetPayloadSize:HEADER_68_X_OFFSET_PAYLOAD_SIZE offsetPayloadCrc:HEADER_68_X_OFFSET_PAYLOAD_CRC offsetVersion:HEADER_68_X_OFFSET_VERSION versionLength:HEADER_68_X_VERSION_LENGTH offsetTimestamp:HEADER_68_X_OFFSET_TIMESTAMP rawBuffer:rawBuffer];
    if (!self)
        return nil;
    [self initializeTypeSpecific];
    return self;
}

- (void) initializeTypeSpecific {
    self.flags = [self.buffer getShort:HEADER_68_X_OFFSET_FLAGS];
    self.execLocation = [self.buffer getInt:HEADER_68_X_OFFSET_EXEC_LOCATION];
    self.payloadOffset = self.execLocation;
}

- (int) signature {
    return HEADER_68_X_SIGNATURE;
}

- (int) headerSize {
    return HEADER_68_X_HEADER_SIZE;
}

- (NSString*) type {
    return HEADER_68_X_TYPE;
}

@end
