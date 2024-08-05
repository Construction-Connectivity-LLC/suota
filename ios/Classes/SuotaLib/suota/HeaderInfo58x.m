/*
 *******************************************************************************
 *
 * Copyright (C) 2019-2020 Dialog Semiconductor.
 * This computer program includes Confidential, Proprietary Information
 * of Dialog Semiconductor. All Rights Reserved.
 *
 *******************************************************************************
 */

#import "HeaderInfo58x.h"
#import "SuotaUtils.h"

#define HEADER_58_X_SIGNATURE 0x7051
#define HEADER_58_X_HEADER_SIZE 64

#define HEADER_58_X_OFFSET_VALID_FLAG 2
#define HEADER_58_X_OFFSET_IMAGE_ID 3
#define HEADER_58_X_OFFSET_PAYLOAD_SIZE 4
#define HEADER_58_X_OFFSET_PAYLOAD_CRC 8
#define HEADER_58_X_OFFSET_VERSION 12
#define HEADER_58_X_VERSION_LENGTH 16
#define HEADER_58_X_OFFSET_TIMESTAMP 28
#define HEADER_58_X_OFFSET_ENCRYPTION 32
#define HEADER_58_X_OFFSET_PAYLOAD 64


@implementation HeaderInfo58x

static NSString* const HEADER_58_X_TYPE = @"58x";

+ (NSString*) TYPE {
    return HEADER_58_X_TYPE;
}

+ (int) SIGNATURE {
    return HEADER_58_X_SIGNATURE;
}

+ (int) HEADER_SIZE {
    return HEADER_58_X_HEADER_SIZE;
}

- (instancetype) initWithHeader:(NSData*)header totalBytes:(uint64_t)totalBytes {
    self = [super initWithOffsetPayloadSize:HEADER_58_X_OFFSET_PAYLOAD_SIZE offsetPayloadCrc:HEADER_58_X_OFFSET_PAYLOAD_CRC offsetVersion:HEADER_58_X_OFFSET_VERSION versionLength:HEADER_58_X_VERSION_LENGTH offsetTimestamp:HEADER_58_X_OFFSET_TIMESTAMP header:header totalBytes:totalBytes];
    if (!self)
        return nil;
    [self initializeTypeSpecific];
    return self;
}

- (instancetype) initWithRawBuffer:(NSData*)rawBuffer {
    self = [super initWithOffsetPayloadSize:HEADER_58_X_OFFSET_PAYLOAD_SIZE offsetPayloadCrc:HEADER_58_X_OFFSET_PAYLOAD_CRC offsetVersion:HEADER_58_X_OFFSET_VERSION versionLength:HEADER_58_X_VERSION_LENGTH offsetTimestamp:HEADER_58_X_OFFSET_TIMESTAMP rawBuffer:rawBuffer];
    if (!self)
        return nil;
    [self initializeTypeSpecific];
    return self;
}

- (void) initializeTypeSpecific {
    self.payloadOffset = HEADER_58_X_OFFSET_PAYLOAD;
    self.validFlag = [self.buffer get:HEADER_58_X_OFFSET_VALID_FLAG];
    self.imageId = [self.buffer get:HEADER_58_X_OFFSET_IMAGE_ID];
    self.encryption = [self.buffer get:HEADER_58_X_OFFSET_ENCRYPTION];
}

- (int) signature {
    return HEADER_58_X_SIGNATURE;
}

- (int) headerSize {
    return HEADER_58_X_HEADER_SIZE;
}

- (NSString*) type {
    return HEADER_58_X_TYPE;
}

@end
