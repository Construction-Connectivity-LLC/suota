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

#define SuotaLog(TAG, fmt, ...) NSLog(@"%@: " fmt, TAG, ##__VA_ARGS__)
#define SuotaLogOpt(enabled, TAG, fmt, ...) do { if (enabled) NSLog(@"%@: " fmt, TAG, ##__VA_ARGS__); } while(0)

#define SUOTA_LIB_LOG_SCAN_DEBUG true
#define SUOTA_LIB_LOG_SCAN_ERROR true

#define SUOTA_LIB_LOG_MANAGER true
#define SUOTA_LIB_LOG_PROTOCOL true
#define SUOTA_LIB_LOG_BLOCK true
#define SUOTA_LIB_LOG_CHUNK true
#define SUOTA_LIB_LOG_GATT_OPERATION false
#define SUOTA_LIB_LOG_SUOTA_FILE true


@interface SuotaLibLog : NSObject

@property (class, readonly) BOOL SCAN_DEBUG;
@property (class, readonly) BOOL SCAN_ERROR;
@property (class, readonly) BOOL MANAGER;
@property (class, readonly) BOOL PROTOCOL;
@property (class, readonly) BOOL BLOCK;
@property (class, readonly) BOOL CHUNK;
@property (class, readonly) BOOL GATT_OPERATION;
@property (class, readonly) BOOL SUOTA_FILE;

@end
