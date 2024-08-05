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

@interface HeaderInfo68x : HeaderInfo

/*
 typedef struct {
 uint8_t signature[2];
 uint16_t flags;
 uint32_t code_size;
 uint32_t crc;
 uint8_t version[16];
 uint32_t timestamp;
 uint32_t exec_location;
 } __attribute__((packed)) suota_1_1_image_header_t;
 
 #define SUOTA_1_1_IMAGE_HEADER_SIGNATURE_B1     0x70
 #define SUOTA_1_1_IMAGE_HEADER_SIGNATURE_B2     0x61
 */

@property (class, readonly) NSString* TYPE;
@property (class, readonly) int SIGNATURE;
@property (class, readonly) int HEADER_SIZE;

@property uint16_t flags;
@property uint64_t execLocation;

- (instancetype) initWithHeader:(NSData*)header totalBytes:(uint64_t)totalBytes;
- (instancetype) initWithRawBuffer:(NSData*)rawBuffer;

@end
