/*
 *******************************************************************************
 *
 * Copyright (C) 2019-2020 Dialog Semiconductor.
 * This computer program includes Confidential, Proprietary Information
 * of Dialog Semiconductor. All Rights Reserved.
 *
 *******************************************************************************
 */

#import "SuotaProfile.h"

static CBUUID* SUOTA_SERVICE_UUID;
static CBUUID* SUOTA_MEM_DEV_UUID;
static CBUUID* SUOTA_GPIO_MAP_UUID;
static CBUUID* SUOTA_MEM_INFO_UUID;
static CBUUID* SUOTA_PATCH_LEN_UUID;
static CBUUID* SUOTA_PATCH_DATA_UUID;
static CBUUID* SUOTA_SERV_STATUS_UUID;
static CBUUID* CLIENT_CONFIG_DESCRIPTOR;
static CBUUID* SUOTA_VERSION_UUID;
static CBUUID* SUOTA_PATCH_DATA_CHAR_SIZE_UUID;
static CBUUID* SUOTA_MTU_UUID;
static CBUUID* SUOTA_L2CAP_PSM_UUID;
static CBUUID* SERVICE_DEVICE_INFORMATION;
static CBUUID* CHARACTERISTIC_MANUFACTURER_NAME_STRING;
static CBUUID* CHARACTERISTIC_MODEL_NUMBER_STRING;
static CBUUID* CHARACTERISTIC_SERIAL_NUMBER_STRING;
static CBUUID* CHARACTERISTIC_HARDWARE_REVISION_STRING;
static CBUUID* CHARACTERISTIC_FIRMWARE_REVISION_STRING;
static CBUUID* CHARACTERISTIC_SOFTWARE_REVISION_STRING;
static CBUUID* CHARACTERISTIC_SYSTEM_ID;
static CBUUID* CHARACTERISTIC_IEEE_11073;
static CBUUID* CHARACTERISTIC_PNP_ID;
static NSMutableDictionary<NSNumber*, NSString*>* suotaErrorCodeList;
static NSArray<NSNumber*>* suotaProtocolStateArray;
static NSMutableDictionary<NSNumber*, NSString*>* suotaStateDescriptionList;
static NSMutableDictionary<NSNumber*, NSString*>* notificationValueDescriptionList;

@implementation SuotaProfile

+ (void) initialize {
    if (self != SuotaProfile.class)
        return;

    SUOTA_SERVICE_UUID = [CBUUID UUIDWithString:@"0000fef5-0000-1000-8000-00805f9b34fb"];
    SUOTA_MEM_DEV_UUID = [CBUUID UUIDWithString:@"8082caa8-41a6-4021-91c6-56f9b954cc34"];
    SUOTA_GPIO_MAP_UUID = [CBUUID UUIDWithString:@"724249f0-5eC3-4b5f-8804-42345af08651"];
    SUOTA_MEM_INFO_UUID = [CBUUID UUIDWithString:@"6c53db25-47a1-45fe-a022-7c92fb334fd4"];
    SUOTA_PATCH_LEN_UUID = [CBUUID UUIDWithString:@"9d84b9a3-000c-49d8-9183-855b673fda31"];
    SUOTA_PATCH_DATA_UUID = [CBUUID UUIDWithString:@"457871e8-d516-4ca1-9116-57d0b17b9cb2"];
    SUOTA_SERV_STATUS_UUID = [CBUUID UUIDWithString:@"5f78df94-798c-46f5-990a-b3eb6a065c88"];
    CLIENT_CONFIG_DESCRIPTOR = [CBUUID UUIDWithString:@"00002902-0000-1000-8000-00805f9b34fb"];
    
    SUOTA_VERSION_UUID = [CBUUID UUIDWithString:@"64B4E8B5-0DE5-401B-A21D-ACC8DB3B913A"];
    SUOTA_PATCH_DATA_CHAR_SIZE_UUID = [CBUUID UUIDWithString:@"42C3DFDD-77BE-4D9C-8454-8F875267FB3B"];
    SUOTA_MTU_UUID = [CBUUID UUIDWithString:@"B7DE1EEA-823D-43BB-A3AF-C4903DFCE23C"];
    SUOTA_L2CAP_PSM_UUID = [CBUUID UUIDWithString:@"61C8849C-F639-4765-946E-5C3419BEBB2A"];

    SERVICE_DEVICE_INFORMATION = [CBUUID UUIDWithString:@"0000180a-0000-1000-8000-00805f9b34fb"];
    CHARACTERISTIC_MANUFACTURER_NAME_STRING = [CBUUID UUIDWithString:@"00002A29-0000-1000-8000-00805f9b34fb"];
    CHARACTERISTIC_MODEL_NUMBER_STRING = [CBUUID UUIDWithString:@"00002A24-0000-1000-8000-00805f9b34fb"];
    CHARACTERISTIC_SERIAL_NUMBER_STRING = [CBUUID UUIDWithString:@"00002A25-0000-1000-8000-00805f9b34fb"];
    CHARACTERISTIC_HARDWARE_REVISION_STRING = [CBUUID UUIDWithString:@"00002A27-0000-1000-8000-00805f9b34fb"];
    CHARACTERISTIC_FIRMWARE_REVISION_STRING = [CBUUID UUIDWithString:@"00002A26-0000-1000-8000-00805f9b34fb"];
    CHARACTERISTIC_SOFTWARE_REVISION_STRING = [CBUUID UUIDWithString:@"00002A28-0000-1000-8000-00805f9b34fb"];
    CHARACTERISTIC_SYSTEM_ID = [CBUUID UUIDWithString:@"00002A23-0000-1000-8000-00805f9b34fb"];
    CHARACTERISTIC_IEEE_11073 = [CBUUID UUIDWithString:@"00002A2A-0000-1000-8000-00805f9b34fb"];
    CHARACTERISTIC_PNP_ID = [CBUUID UUIDWithString:@"00002A50-0000-1000-8000-00805f9b34fb"];

    suotaErrorCodeList = [NSMutableDictionary dictionary];
    suotaErrorCodeList[@(SPOTA_SRV_STARTED)] = @"SPOTA service started instead of SUOTA.";
    suotaErrorCodeList[@(SRV_EXIT)] = @"Forced exit of SUOTA service.";
    suotaErrorCodeList[@(CRC_MISMATCH)] = @"Patch Data CRC mismatch.";
    suotaErrorCodeList[@(PATCH_LENGTH_ERROR)] = @"Received patch length not equal to PATCH_LEN characteristic value.";
    suotaErrorCodeList[@(EXTERNAL_MEMORY_ERROR)] = @"External Memory Error. Writing to external device failed.";
    suotaErrorCodeList[@(INTERNAL_MEMORY_ERROR)] = @"Internal Memory Error. Not enough internal memory space for patch.";
    suotaErrorCodeList[@(INVALID_MEMORY_TYPE)] = @"Invalid memory device.";
    suotaErrorCodeList[@(APPLICATION_ERROR)] = @"Application error.";
    suotaErrorCodeList[@(INVALID_IMAGE_BANK)] = @"Invalid image bank.";
    suotaErrorCodeList[@(INVALID_IMAGE_HEADER)] = @"Invalid image header.";
    suotaErrorCodeList[@(INVALID_IMAGE_SIZE)] = @"Invalid image size.";
    suotaErrorCodeList[@(INVALID_PRODUCT_HEADER)] = @"Invalid product header.";
    suotaErrorCodeList[@(SAME_IMAGE_ERROR)] = @"Same Image Error.";
    suotaErrorCodeList[@(EXTERNAL_MEMORY_READ_ERROR)] = @"Failed to read from external memory device.";
    suotaErrorCodeList[@(SUOTA_NOT_SUPPORTED)] = @"The remote device does not support SUOTA.";
    suotaErrorCodeList[@(SERVICE_DISCOVERY_ERROR)] = @"Service discovery error.";
    suotaErrorCodeList[@(GATT_OPERATION_ERROR)] = @"GATT operation error.";
    suotaErrorCodeList[@(MTU_REQUEST_FAILED)] = @"MTU request failed.";
    suotaErrorCodeList[@(FIRMWARE_LOAD_FAILED)] = @"Failed to load the firmware file.";
    suotaErrorCodeList[@(INVALID_FIRMWARE_CRC)] = @"Firmware CRC validation failed.";
    suotaErrorCodeList[@(UPLOAD_TIMEOUT)] = @"File upload timeout.";
    suotaErrorCodeList[@(PROTOCOL_ERROR)] = @"Unexpected behavior while running SUOTA protocol.";
    suotaErrorCodeList[@(NOT_CONNECTED)] = @"Device not connected.";

    suotaProtocolStateArray = @[ @(ENABLE_NOTIFICATIONS), @(SET_MEMORY_DEVICE), @(SET_GPIO_MAP), @(SEND_BLOCK), @(END_SIGNAL), @(ERROR) ];
    
    suotaStateDescriptionList = [NSMutableDictionary dictionary];
    suotaStateDescriptionList[@(ENABLE_NOTIFICATIONS)] = @"ENABLE_NOTIFICATIONS";
    suotaStateDescriptionList[@(SET_MEMORY_DEVICE)] = @"SET_MEMORY_DEVICE";
    suotaStateDescriptionList[@(SET_GPIO_MAP)] = @"SET_GPIO_MAP";
    suotaStateDescriptionList[@(SEND_BLOCK)] = @"SEND_BLOCK";
    suotaStateDescriptionList[@(END_SIGNAL)] = @"END_SIGNAL";
    suotaStateDescriptionList[@(ERROR)] = @"ERROR";
    
    notificationValueDescriptionList = [NSMutableDictionary dictionary];
    notificationValueDescriptionList[@(SERVICE_STATUS_OK)] = @"SERVICE_STATUS_OK";
    notificationValueDescriptionList[@(IMAGE_STARTED)] = @"IMAGE_STARTED";
}

+ (CBUUID*) SUOTA_SERVICE_UUID {
    return SUOTA_SERVICE_UUID;
}

+ (CBUUID*) SUOTA_MEM_DEV_UUID {
    return SUOTA_MEM_DEV_UUID;
}

+ (CBUUID*) SUOTA_GPIO_MAP_UUID {
    return SUOTA_GPIO_MAP_UUID;
}

+ (CBUUID*) SUOTA_MEM_INFO_UUID {
    return SUOTA_MEM_INFO_UUID;
}

+ (CBUUID*) SUOTA_PATCH_LEN_UUID {
    return SUOTA_PATCH_LEN_UUID;
}

+ (CBUUID*) SUOTA_PATCH_DATA_UUID {
    return SUOTA_PATCH_DATA_UUID;
}

+ (CBUUID*) SUOTA_SERV_STATUS_UUID {
    return SUOTA_SERV_STATUS_UUID;
}

+ (CBUUID*) CLIENT_CONFIG_DESCRIPTOR {
    return CLIENT_CONFIG_DESCRIPTOR;
}

+ (CBUUID*) SUOTA_VERSION_UUID {
    return SUOTA_VERSION_UUID;
}

+ (CBUUID*) SUOTA_PATCH_DATA_CHAR_SIZE_UUID {
    return SUOTA_PATCH_DATA_CHAR_SIZE_UUID;
}

+ (CBUUID*) SUOTA_MTU_UUID {
    return SUOTA_MTU_UUID;
}

+ (CBUUID*) SUOTA_L2CAP_PSM_UUID {
    return SUOTA_L2CAP_PSM_UUID;
}

+ (CBUUID*) SERVICE_DEVICE_INFORMATION {
    return SERVICE_DEVICE_INFORMATION;
}

+ (CBUUID*) CHARACTERISTIC_MANUFACTURER_NAME_STRING {
    return CHARACTERISTIC_MANUFACTURER_NAME_STRING;
}

+ (CBUUID*) CHARACTERISTIC_MODEL_NUMBER_STRING {
    return CHARACTERISTIC_MODEL_NUMBER_STRING;
}

+ (CBUUID*) CHARACTERISTIC_SERIAL_NUMBER_STRING {
    return CHARACTERISTIC_SERIAL_NUMBER_STRING;
}

+ (CBUUID*) CHARACTERISTIC_HARDWARE_REVISION_STRING {
    return CHARACTERISTIC_HARDWARE_REVISION_STRING;
}

+ (CBUUID*) CHARACTERISTIC_FIRMWARE_REVISION_STRING {
    return CHARACTERISTIC_FIRMWARE_REVISION_STRING;
}

+ (CBUUID*) CHARACTERISTIC_SOFTWARE_REVISION_STRING {
    return CHARACTERISTIC_SOFTWARE_REVISION_STRING;
}

+ (CBUUID*) CHARACTERISTIC_SYSTEM_ID {
    return CHARACTERISTIC_SYSTEM_ID;
}

+ (CBUUID*) CHARACTERISTIC_IEEE_11073 {
    return CHARACTERISTIC_IEEE_11073;
}

+ (CBUUID*) CHARACTERISTIC_PNP_ID {
    return CHARACTERISTIC_PNP_ID;
}

+ (int) DEFAULT_MTU {
    return SUOTA_DEFAULT_MTU;
}

+ (NSMutableDictionary<NSNumber*, NSString*>*) suotaErrorCodeList {
    return suotaErrorCodeList;
}

+ (NSArray<NSNumber*>*) suotaProtocolStateArray {
    return suotaProtocolStateArray;
}

+ (NSMutableDictionary<NSNumber*, NSString*>*) suotaStateDescriptionList {
    return suotaStateDescriptionList;
}

+ (NSMutableDictionary<NSNumber*, NSString*>*) notificationValueDescriptionList {
    return notificationValueDescriptionList;
}

@end
