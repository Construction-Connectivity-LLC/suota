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

@interface HeaderInfo58x : HeaderInfo

/*
 typedef struct
 {
 uint8_t signature[2];
 uint8_t validflag;      // Set to STATUS_VALID_IMAGE at the end of the image update
 uint8_t imageid;        // it is used to determine which image is the newest
 uint32_t code_size;     // Image size
 uint32_t CRC ;          // Image CRC
 uint8_t version[16];    // Vertion of the image
 uint32_t timestamp;
 uint8_t encryption;
 uint8_t reserved[31];
 } image_header_t;
 
 #define IMAGE_HEADER_SIGNATURE1     0x70
 #define IMAGE_HEADER_SIGNATURE2     0x51
 */

@property (class, readonly) NSString* TYPE;
@property (class, readonly) int SIGNATURE;
@property (class, readonly) int HEADER_SIZE;

@property uint8_t validFlag;
@property uint8_t imageId;
@property uint8_t encryption;

- (instancetype) initWithHeader:(NSData*)header totalBytes:(uint64_t)totalBytes;
- (instancetype) initWithRawBuffer:(NSData*)rawBuffer;

@end
