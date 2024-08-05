/*
 *******************************************************************************
 *
 * Copyright (C) 2019-2020 Dialog Semiconductor.
 * This computer program includes Confidential, Proprietary Information
 * of Dialog Semiconductor. All Rights Reserved.
 *
 *******************************************************************************
 */

/*!
 @header SuotaProfile.h
 @brief Header file about the library configuration.
 
 This header file contains global values about protocol states and error codes.
 
 @copyright 2019 Dialog Semiconductor
 */

#import <CoreBluetooth/CoreBluetooth.h>
#import <Foundation/Foundation.h>

#define SUOTA_DEFAULT_MTU 23

/*!
 * @abstract Scan status.
 * @constant STARTED, Scanning process started.
 * @constant STOPPED, Scanning process stopped.
 *
 */
enum ScanStatus {
    STARTED,
    STOPPED
};

/*!
 * @abstract Scan failure codes.
 * @constant FAIL, Generic scan failure.
 * @constant BLE_NOT_SUPPORTED, Bluetooth Low Energy is not supported on this device.
 * @constant BLUETOOTH_NOT_ENABLED, The Bluetooth adapter is disabled.
 *
 */
enum ScanFailure {
    FAIL,
    BLE_NOT_SUPPORTED,
    BLUETOOTH_NOT_ENABLED,
};

/*!
 * @abstract State of the {@link SuotaManager}.
 * @constant CONNECTED, The BLE device to perform the SUOTA is connected with the device.
 * @constant DISCONNECTED, The BLE device to perform the SUOTA is not connected with the device.
 *
 */
enum SuotaManagerStatus {
    CONNECTED,
    DISCONNECTED
};

/*!
 * @abstract State of the device info read process.
 * @constant NO_DEVICE_INFO, There are not any info characteristics to read from the device.
 * @constant SUCCESS, The specified info characteristics have been successfully read.
 *
 */
enum DeviceInfoReadStatus {
    NO_DEVICE_INFO,
    SUCCESS
};

/*!
 * @abstract State of the SUOTA process.
 * @constant ENABLE_NOTIFICATIONS, Enables notifications on the <code>SUOTA_SERV_STATUS</code> characteristic.
 * @constant SET_MEMORY_DEVICE, Defines where the patch will be stored on the device upon reception.
 * @constant SET_GPIO_MAP, Defines the mapping of the interfaces on various GPIO pins.
 * @constant SEND_BLOCK, Sends a block of the patch to the device.
 * @constant END_SIGNAL, Sends the SUOTA end command to the device.
 * @constant ERROR, Error state.
 *
 */
enum SuotaProtocolState {
    ENABLE_NOTIFICATIONS,
    SET_MEMORY_DEVICE,
    SET_GPIO_MAP,
    SEND_BLOCK,
    END_SIGNAL,
    ERROR
};

/*!
 * @abstract Characteristic groups.
 * @constant DEVICE_INFO, Characteristics containing info about the device.
 * @constant SUOTA_INFO, Characteristics containing info about the SUOTA.
 * @constant OTHER, Characteristics that do not belong in any other group.
 *
 */
enum CharacteristicGroup {
    DEVICE_INFO,
    SUOTA_INFO,
    OTHER
};

/*!
 * @enum PhysicalDeviceType
 * @abstract Physical device where the patch will be saved.
 * @constant MEMORY_TYPE_EXTERNAL_I2C, Image is stored in I2C EEPROM.
 * @constant MEMORY_TYPE_EXTERNAL_SPI, Image is stored in SPI Flash.
 *
 */
enum {
    MEMORY_TYPE_EXTERNAL_I2C = 0x12,
    MEMORY_TYPE_EXTERNAL_SPI = 0x13,
};

/*!
 * @enum MemoryBank
 * @abstract Memory bank where the patch will be stored.
 * @constant IMAGE_BANK_OLDEST, Image bank oldest.
 * @constant IMAGE_BANK_1, Image bank #1.
 * @constant IMAGE_BANK_2, Image bank #2.
 *
 */
enum {
    IMAGE_BANK_OLDEST = 0x00,
    IMAGE_BANK_1 = 0x01,
    IMAGE_BANK_2 = 0x02,
};

enum {
    SERVICE_STATUS_OK = 0x02,
    IMAGE_STARTED = 0x10,
};

enum {
    SUOTA_END = 0xfe000000,
    SUOTA_REBOOT = 0xfd000000,
    SUOTA_ABORT = 0xff000000,
};

/*!
 * @abstract SUOTA protocol errors that may arise during a SUOTA process.
 * @constant SPOTA_SRV_STARTED, SPOTA service started instead of SUOTA.
 * @constant SRV_EXIT, Forced exit of SUOTA service.
 * @constant CRC_MISMATCH, Patch Data CRC mismatch.
 * @constant PATCH_LENGTH_ERROR, Received patch length not equal to <code>PATCH_LEN</code> characteristic value.
 * @constant EXTERNAL_MEMORY_ERROR, Writing to external device failed.
 * @constant INTERNAL_MEMORY_ERROR, Not enough internal memory space for patch.
 * @constant INVALID_MEMORY_TYPE, Invalid memory device.
 * @constant APPLICATION_ERROR, Application error.
 * @constant INVALID_IMAGE_BANK, Invalid image bank.
 * @constant INVALID_IMAGE_HEADER, Invalid image header.
 * @constant INVALID_IMAGE_SIZE, Invalid image size.
 * @constant INVALID_PRODUCT_HEADER, Invalid product header.
 * @constant SAME_IMAGE_ERROR, Same Image Error.
 * @constant EXTERNAL_MEMORY_READ_ERROR, Failed to read from external memory device.
 *
 */
enum SuotaErrors {
    SPOTA_SRV_STARTED = 0x01,
    SRV_EXIT = 0x03,
    CRC_MISMATCH = 0x04,
    PATCH_LENGTH_ERROR = 0x05,
    EXTERNAL_MEMORY_ERROR = 0x06,
    INTERNAL_MEMORY_ERROR = 0x07,
    INVALID_MEMORY_TYPE = 0x08,
    APPLICATION_ERROR = 0x09,
    INVALID_IMAGE_BANK = 0x11,
    INVALID_IMAGE_HEADER = 0x12,
    INVALID_IMAGE_SIZE = 0x13,
    INVALID_PRODUCT_HEADER = 0x14,
    SAME_IMAGE_ERROR = 0x15,
    EXTERNAL_MEMORY_READ_ERROR = 0x16,
};

// Application error codes (must be greater than 255 in order not to conflict with SUOTA error codes)
/*!
 * @abstract Application errors that may arise during a SUOTA process.
 * @constant SUOTA_NOT_SUPPORTED, The remote device does not support SUOTA.
 * @constant SERVICE_DISCOVERY_ERROR, Error discovering services.
 * @constant GATT_OPERATION_ERROR, Communication error.
 * @constant MTU_REQUEST_FAILED, Failed to request MTU size.
 * @constant FIRMWARE_LOAD_FAILED, Failed to load the firmware file.
 * @constant INVALID_FIRMWARE_CRC, Firmware validation failed.
 * @constant UPLOAD_TIMEOUT, File upload timeout.
 * @constant PROTOCOL_ERROR, Unexpected protocol behavior.
 * @constant NOT_CONNECTED, Isn't connected to a BLE device to perform SUOTA.
 *
 */
enum ApplicationErrors {
    SUOTA_NOT_SUPPORTED = 0xffff,
    SERVICE_DISCOVERY_ERROR = 0xfffe,
    GATT_OPERATION_ERROR = 0xfffd,
    MTU_REQUEST_FAILED = 0xfffc,
    FIRMWARE_LOAD_FAILED = 0xfffb,
    INVALID_FIRMWARE_CRC = 0xfffa,
    UPLOAD_TIMEOUT = 0xfff9,
    PROTOCOL_ERROR = 0xfff8,
    NOT_CONNECTED = 0xfff7,
};

@interface SuotaProfile : NSObject

@property (class, readonly) CBUUID* SUOTA_SERVICE_UUID;
@property (class, readonly) CBUUID* SUOTA_MEM_DEV_UUID;
@property (class, readonly) CBUUID* SUOTA_GPIO_MAP_UUID;
@property (class, readonly) CBUUID* SUOTA_MEM_INFO_UUID;
@property (class, readonly) CBUUID* SUOTA_PATCH_LEN_UUID;
@property (class, readonly) CBUUID* SUOTA_PATCH_DATA_UUID;
@property (class, readonly) CBUUID* SUOTA_SERV_STATUS_UUID;
@property (class, readonly) CBUUID* CLIENT_CONFIG_DESCRIPTOR;

@property (class, readonly) CBUUID* SUOTA_VERSION_UUID;
@property (class, readonly) CBUUID* SUOTA_PATCH_DATA_CHAR_SIZE_UUID;
@property (class, readonly) CBUUID* SUOTA_MTU_UUID;
@property (class, readonly) CBUUID* SUOTA_L2CAP_PSM_UUID;

@property (class, readonly) CBUUID* SERVICE_DEVICE_INFORMATION;
@property (class, readonly) CBUUID* CHARACTERISTIC_MANUFACTURER_NAME_STRING;
@property (class, readonly) CBUUID* CHARACTERISTIC_MODEL_NUMBER_STRING;
@property (class, readonly) CBUUID* CHARACTERISTIC_SERIAL_NUMBER_STRING;
@property (class, readonly) CBUUID* CHARACTERISTIC_HARDWARE_REVISION_STRING;
@property (class, readonly) CBUUID* CHARACTERISTIC_FIRMWARE_REVISION_STRING;
@property (class, readonly) CBUUID* CHARACTERISTIC_SOFTWARE_REVISION_STRING;
@property (class, readonly) CBUUID* CHARACTERISTIC_SYSTEM_ID;
@property (class, readonly) CBUUID* CHARACTERISTIC_IEEE_11073;
@property (class, readonly) CBUUID* CHARACTERISTIC_PNP_ID;

@property (class, readonly) int DEFAULT_MTU;

@property (class, readonly) NSMutableDictionary<NSNumber*, NSString*>* suotaErrorCodeList;

@property (class, readonly) NSArray<NSNumber*>* suotaProtocolStateArray;

@property (class, readonly) NSMutableDictionary<NSNumber*, NSString*>* suotaStateDescriptionList;
@property (class, readonly) NSMutableDictionary<NSNumber*, NSString*>* notificationValueDescriptionList;

@end
