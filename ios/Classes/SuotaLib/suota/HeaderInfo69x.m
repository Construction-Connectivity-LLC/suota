/*
 *******************************************************************************
 *
 * Copyright (C) 2019-2020 Dialog Semiconductor.
 * This computer program includes Confidential, Proprietary Information
 * of Dialog Semiconductor. All Rights Reserved.
 *
 *******************************************************************************
 */

#import "HeaderInfo69x.h"
#import "SuotaUtils.h"

#define HEADER_69_X_SIGNATURE 0x5171
#define HEADER_69_X_HEADER_SIZE 34

#define HEADER_69_X_OFFSET_PAYLOAD_SIZE 2
#define HEADER_69_X_OFFSET_PAYLOAD_CRC 6
#define HEADER_69_X_OFFSET_VERSION 10
#define HEADER_69_X_VERSION_LENGTH 16
#define HEADER_69_X_OFFSET_TIMESTAMP 26
#define HEADER_69_X_OFFSET_POINTER_TO_IVT 30


@implementation HeaderInfo69x

static NSString* const HEADER_69_X_TYPE = @"69x";

+ (NSString*) TYPE {
    return HEADER_69_X_TYPE;
}

+ (int) SIGNATURE {
    return HEADER_69_X_SIGNATURE;
}

+ (int) HEADER_SIZE {
    return HEADER_69_X_HEADER_SIZE;
}

- (instancetype) initWithHeader:(NSData*)header totalBytes:(uint64_t)totalBytes {
    self = [super initWithOffsetPayloadSize:HEADER_69_X_OFFSET_PAYLOAD_SIZE offsetPayloadCrc:HEADER_69_X_OFFSET_PAYLOAD_CRC offsetVersion:HEADER_69_X_OFFSET_VERSION versionLength:HEADER_69_X_VERSION_LENGTH offsetTimestamp:HEADER_69_X_OFFSET_TIMESTAMP header:header totalBytes:totalBytes];
    if (!self)
        return nil;
    [self initializeTypeSpecific];
    return self;
}

- (instancetype) initWithRawBuffer:(NSData*)rawBuffer {
    self = [super initWithOffsetPayloadSize:HEADER_69_X_OFFSET_PAYLOAD_SIZE offsetPayloadCrc:HEADER_69_X_OFFSET_PAYLOAD_CRC offsetVersion:HEADER_69_X_OFFSET_VERSION versionLength:HEADER_69_X_VERSION_LENGTH offsetTimestamp:HEADER_69_X_OFFSET_TIMESTAMP rawBuffer:rawBuffer];
    if (!self)
        return nil;
    [self initializeTypeSpecific];
    return self;
}

- (void) initializeTypeSpecific {
    self.pointerToIvt = [self.buffer getInt:HEADER_69_X_OFFSET_POINTER_TO_IVT];
    self.payloadOffset = self.pointerToIvt;
}

- (int) signature {
    return HEADER_69_X_SIGNATURE;
}

- (int) headerSize {
    return HEADER_69_X_HEADER_SIZE;
}

- (NSString*) type {
    return HEADER_69_X_TYPE;
}

@end
