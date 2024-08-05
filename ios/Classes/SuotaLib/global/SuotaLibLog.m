/*
 *******************************************************************************
 *
 * Copyright (C) 2019-2020 Dialog Semiconductor.
 * This computer program includes Confidential, Proprietary Information
 * of Dialog Semiconductor. All Rights Reserved.
 *
 *******************************************************************************
 */

#import "SuotaLibLog.h"

@implementation SuotaLibLog

+ (BOOL) SCAN_DEBUG {
    return SUOTA_LIB_LOG_SCAN_DEBUG;
}

+ (BOOL) SCAN_ERROR {
    return SUOTA_LIB_LOG_SCAN_ERROR;
}

+ (BOOL) MANAGER {
    return SUOTA_LIB_LOG_MANAGER;
}

+ (BOOL) PROTOCOL {
    return SUOTA_LIB_LOG_PROTOCOL;
}

+ (BOOL) BLOCK {
    return SUOTA_LIB_LOG_BLOCK;
}

+ (BOOL) CHUNK {
    return SUOTA_LIB_LOG_CHUNK;
}

+ (BOOL) GATT_OPERATION {
    return SUOTA_LIB_LOG_GATT_OPERATION;
}

+ (BOOL) SUOTA_FILE {
    return SUOTA_LIB_LOG_SUOTA_FILE;
}

@end
