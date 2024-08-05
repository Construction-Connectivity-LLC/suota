/*
 *******************************************************************************
 *
 * Copyright (C) 2019-2020 Dialog Semiconductor.
 * This computer program includes Confidential, Proprietary Information
 * of Dialog Semiconductor. All Rights Reserved.
 *
 *******************************************************************************
 */

#import <Foundation/Foundation.h>

@class SuotaByteBuffer;

@interface HeaderInfo : NSObject

@property (class, readonly) int SIGNATURE_LENGTH;

@property int signature;
@property NSString* type;
@property int headerSize;
@property uint64_t payloadOffset;
@property int offsetPayloadSize;
@property int offsetPayloadCrc;
@property int offsetVersion;
@property int versionLength;
@property int offsetTimestamp;

@property NSData* header;
@property uint64_t totalBytes;
@property SuotaByteBuffer* buffer;
@property uint64_t payloadSize;
@property uint64_t payloadCrc;
@property NSString* version;
@property NSData* versionRaw;
@property uint64_t timestamp;

- (instancetype) initWithOffsetPayloadSize:(int)offsetPayloadSize offsetPayloadCrc:(int)offsetPayloadCrc offsetVersion:(int)offsetVersion versionLength:(int)versionLength offsetTimestamp:(int)offsetTimestamp header:(NSData*)header totalBytes:(uint64_t)totalBytes;
- (instancetype) initWithOffsetPayloadSize:(int)offsetPayloadSize offsetPayloadCrc:(int)offsetPayloadCrc offsetVersion:(int)offsetVersion versionLength:(int)versionLength offsetTimestamp:(int)offsetTimestamp rawBuffer:(NSData*)rawBuffer;

@end
