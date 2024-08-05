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

@interface SuotaUtils : NSObject

+ (NSString*) hexArray:(NSData*)v uppercase:(BOOL)uppercase brackets:(BOOL)brackets;
+ (NSString*) hexArray:(NSData*)v;

@end

@interface SuotaByteBuffer : NSObject

enum {
    SuotaByteBufferBigEndian,
    SuotaByteBufferLittleEndian,
};

@property NSData* data;
@property int order;
@property int position;

- (instancetype) initWithCapacity:(int)capacity;
- (instancetype) initWithBuffer:(NSData*)data;

+ (instancetype) allocate:(int)capacity;
+ (instancetype) allocate:(int)capacity order:(int)order;
+ (instancetype) wrap:(NSData*)data;
+ (instancetype) wrap:(NSData*)data order:(int)order;
+ (instancetype) wrap:(NSData*)data offset:(int)offset length:(int)length order:(int)order;

- (void) put:(uint8_t)v;
- (void) putShort:(uint16_t)v;
- (void) putInt:(uint32_t)v;
- (void) putLong:(uint64_t)v;
- (void) putData:(NSData*)v;
- (void) put:(const uint8_t*)v length:(int)length;

- (uint8_t) get;
- (uint16_t) getShort;
- (uint32_t) getInt;
- (uint64_t) getLong;
- (NSData*) getData:(int)length;

- (uint8_t) get:(int)position;
- (uint16_t) getShort:(int)position;
- (uint32_t) getInt:(int)position;
- (uint64_t) getLong:(int)position;
- (NSData*) getData:(int)position length:(int)length;

- (int) remaining;
- (BOOL) hasRemaining;

@end
