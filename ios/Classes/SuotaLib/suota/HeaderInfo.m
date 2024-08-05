/*
 *******************************************************************************
 *
 * Copyright (C) 2019-2020 Dialog Semiconductor.
 * This computer program includes Confidential, Proprietary Information
 * of Dialog Semiconductor. All Rights Reserved.
 *
 *******************************************************************************
 */

#import "HeaderInfo.h"
#import "HeaderInfo58x.h"
#import "HeaderInfo68x.h"
#import "HeaderInfo69x.h"
#import "SuotaUtils.h"
#import "SuotaLibLog.h"

@implementation HeaderInfo

static NSString* const TAG = @"HeaderInfo";
static int const SIGNATURE_LENGTH = 2;

+ (int) SIGNATURE_LENGTH {
    return SIGNATURE_LENGTH;
}

- (instancetype) initWithOffsetPayloadSize:(int)offsetPayloadSize offsetPayloadCrc:(int)offsetPayloadCrc offsetVersion:(int)offsetVersion versionLength:(int)versionLength offsetTimestamp:(int)offsetTimestamp header:(NSData*)header totalBytes:(uint64_t)totalBytes {
    self = [self initWithOffsetPayloadSize:offsetPayloadSize offsetPayloadCrc:offsetPayloadCrc offsetVersion:offsetVersion versionLength:versionLength offsetTimestamp:offsetTimestamp];
    if (!self)
        return nil;
    self.header = header;
    self.totalBytes = totalBytes;
    [self initialize];
    return self;
}

- (instancetype) initWithOffsetPayloadSize:(int)offsetPayloadSize offsetPayloadCrc:(int)offsetPayloadCrc offsetVersion:(int)offsetVersion versionLength:(int)versionLength offsetTimestamp:(int)offsetTimestamp rawBuffer:(NSData*)rawBuffer {
    self = [self initWithOffsetPayloadSize:offsetPayloadSize offsetPayloadCrc:offsetPayloadCrc offsetVersion:offsetVersion versionLength:versionLength offsetTimestamp:offsetTimestamp];
    if (!self)
        return nil;
    self.header = [NSMutableData dataWithCapacity:self.headerSize];
    [(NSMutableData*) self.header appendBytes:rawBuffer.bytes length:self.headerSize];
    self.totalBytes = rawBuffer.length;
    [self initialize];
    return self;
}

- (instancetype) initWithOffsetPayloadSize:(int)offsetPayloadSize offsetPayloadCrc:(int)offsetPayloadCrc offsetVersion:(int)offsetVersion versionLength:(int)versionLength offsetTimestamp:(int)offsetTimestamp {
    self = [super init];
    if (!self)
        return nil;
    self.offsetPayloadSize = offsetPayloadSize;
    self.offsetPayloadCrc = offsetPayloadCrc;
    self.offsetVersion = offsetVersion;
    self.versionLength = versionLength;
    self.offsetTimestamp = offsetTimestamp;
    return self;
}

- (void) initialize {
    self.buffer = [SuotaByteBuffer wrap:self.header order:SuotaByteBufferLittleEndian];

    self.payloadSize = [self.buffer getInt:self.offsetPayloadSize];
    self.payloadCrc = [self.buffer getInt:self.offsetPayloadCrc];
    self.timestamp = [self.buffer getInt:self.offsetTimestamp];
    
    self.versionRaw = [self.header subdataWithRange:NSMakeRange(self.offsetVersion, self.versionLength)];
    const uint8_t* versionBytes = self.versionRaw.bytes;
    int valid = 0;
    for (; valid < self.versionRaw.length; valid++) {
        if (versionBytes[valid] == 0 || versionBytes[valid] == 0xff)
            break;
    }
    self.version = [[NSString alloc] initWithBytes:versionBytes length:valid encoding:NSASCIIStringEncoding];
    self.buffer.position = 0;
}

@end
