/*
 *******************************************************************************
 *
 * Copyright (C) 2019-2020 Dialog Semiconductor.
 * This computer program includes Confidential, Proprietary Information
 * of Dialog Semiconductor. All Rights Reserved.
 *
 *******************************************************************************
 */

#import "SuotaLibConfig.h"
#import "SuotaProfile.h"

static NSArray<CBUUID*>* DEVICE_INFO_TO_READ;
static NSString* DEFAULT_FIRMWARE_PATH;

@implementation SuotaLibConfig

+ (void) initialize {
    if (self != SuotaLibConfig.class)
        return;

    DEVICE_INFO_TO_READ = @[
                            SuotaProfile.CHARACTERISTIC_MANUFACTURER_NAME_STRING,
                            SuotaProfile.CHARACTERISTIC_MODEL_NUMBER_STRING,
                            SuotaProfile.CHARACTERISTIC_FIRMWARE_REVISION_STRING,
                            SuotaProfile.CHARACTERISTIC_SOFTWARE_REVISION_STRING,
                            ];
    
    DEFAULT_FIRMWARE_PATH = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
}

+ (BOOL) ALLOW_DIALOG_DISPLAY {
    return SUOTA_LIB_CONFIG_ALLOW_DIALOG_DISPLAY;
}

+ (BOOL) CHECK_HEADER_CRC {
    return SUOTA_LIB_CONFIG_CHECK_HEADER_CRC;
}

+ (BOOL) CALCULATE_STATISTICS {
    return SUOTA_LIB_CONFIG_CALCULATE_STATISTICS;
}

+ (int) UPLOAD_TIMEOUT {
    return SUOTA_LIB_CONFIG_UPLOAD_TIMEOUT;
}

+ (BOOL) AUTO_REBOOT {
    return SUOTA_LIB_CONFIG_AUTO_REBOOT;
}

+ (BOOL) AUTO_DISCONNECT_IF_REBOOT_DENIED {
    return SUOTA_LIB_CONFIG_AUTO_DISCONNECT_IF_REBOOT_DENIED;
}

+ (BOOL) AUTO_READ_DEVICE_INFO {
    return SUOTA_LIB_CONFIG_AUTO_READ_DEVICE_INFO;
}

+ (BOOL) READ_DEVICE_INFO_FIRST {
    return SUOTA_LIB_CONFIG_READ_DEVICE_INFO_FIRST;
}

+ (BOOL) READ_ALL_DEVICE_INFO {
    return SUOTA_LIB_CONFIG_READ_ALL_DEVICE_INFO;
}

+ (BOOL) NOTIFY_DEVICE_INFO_READ {
    return SUOTA_LIB_CONFIG_NOTIFY_DEVICE_INFO_READ;
}

+ (BOOL) NOTIFY_DEVICE_INFO_READ_COMPLETED {
    return SUOTA_LIB_CONFIG_NOTIFY_DEVICE_INFO_READ_COMPLETED;
}

+ (BOOL) NOTIFY_SUOTA_LOG {
    return SUOTA_LIB_CONFIG_NOTIFY_SUOTA_LOG;
}

+ (BOOL) NOTIFY_SUOTA_LOG_CHUNK {
    return SUOTA_LIB_CONFIG_NOTIFY_SUOTA_LOG_CHUNK;
}

+ (BOOL) NOTIFY_SUOTA_LOG_BLOCK {
    return SUOTA_LIB_CONFIG_NOTIFY_SUOTA_LOG_BLOCK;
}

+ (BOOL) NOTIFY_CHUNK_SEND {
    return SUOTA_LIB_CONFIG_NOTIFY_CHUNK_SEND;
}

+ (BOOL) NOTIFY_BLOCK_SENT {
    return SUOTA_LIB_CONFIG_NOTIFY_BLOCK_SENT;
}

+ (BOOL) NOTIFY_UPLOAD_PROGRESS {
    return SUOTA_LIB_CONFIG_NOTIFY_UPLOAD_PROGRESS;
}

+ (BOOL) PROTOCOL_DEBUG {
    return SUOTA_LIB_CONFIG_PROTOCOL_DEBUG;
}

+ (NSArray<CBUUID*>*) DEVICE_INFO_TO_READ {
    return DEVICE_INFO_TO_READ;
}

+ (int) DEFAULT_SCAN_TIMEOUT {
    return SUOTA_LIB_DEFAULT_SCAN_TIMEOUT;
}

+ (NSString*) DEFAULT_FIRMWARE_PATH {
    return DEFAULT_FIRMWARE_PATH;
}

+ (BOOL) FILE_LIST_HEADER_INFO {
    return SUOTA_LIB_DEFAULT_FILE_LIST_HEADER_INFO;
}

+ (int) DEFAULT_BLOCK_SIZE {
    return SUOTA_LIB_DEFAULT_BLOCK_SIZE;
}

+ (int) DEFAULT_CHUNK_SIZE {
    return SUOTA_LIB_DEFAULT_CHUNK_SIZE;
}

+ (uint8_t) DEFAULT_IMAGE_BANK {
    return SUOTA_LIB_DEFAULT_IMAGE_BANK;
}

+ (uint8_t) DEFAULT_MEMORY_TYPE {
    return SUOTA_LIB_DEFAULT_MEMORY_TYPE;
}

+ (uint8_t) DEFAULT_MISO_GPIO {
    return SUOTA_LIB_DEFAULT_MISO_GPIO;
}

+ (uint8_t) DEFAULT_MOSI_GPIO {
    return SUOTA_LIB_DEFAULT_MOSI_GPIO;
}

+ (uint8_t) DEFAULT_CS_GPIO {
    return SUOTA_LIB_DEFAULT_CS_GPIO;
}

+ (uint8_t) DEFAULT_SCK_GPIO {
    return SUOTA_LIB_DEFAULT_SCK_GPIO;
}

+ (uint8_t) DEFAULT_I2C_DEVICE_ADDRESS {
    return SUOTA_LIB_DEFAULT_I2C_DEVICE_ADDRESS;
}

+ (uint8_t) DEFAULT_SCL_GPIO {
    return SUOTA_LIB_DEFAULT_SCL_GPIO;
}

+ (uint8_t) DEFAULT_SDA_GPIO {
    return SUOTA_LIB_DEFAULT_SDA_GPIO;
}

@end
