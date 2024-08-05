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

@interface HeaderInfo69x : HeaderInfo

/*
 typedef struct {
 uint8_t image_identifier[2];
 uint32_t size;
 uint32_t crc;
 uint8_t version_string[16];
 uint32_t timestamp;
 uint32_t pointer_to_ivt;
 } __attribute__((packed)) suota_1_1_image_header_da1469x_t;
 
 #define SUOTA_1_1_IMAGE_DA1469x_HEADER_SIGNATURE_B1       0x51
 #define SUOTA_1_1_IMAGE_DA1469x_HEADER_SIGNATURE_B2       0x71
 */

@property (class, readonly) NSString* TYPE;
@property (class, readonly) int SIGNATURE;
@property (class, readonly) int HEADER_SIZE;

@property uint64_t pointerToIvt;

- (instancetype) initWithHeader:(NSData*)header totalBytes:(uint64_t)totalBytes;
- (instancetype) initWithRawBuffer:(NSData*)rawBuffer;

@end
