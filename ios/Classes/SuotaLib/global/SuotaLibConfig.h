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
 @header SuotaLibConfig.h
 @brief Header file about the library configuration.
 
 This header file contains value definitions and property declarations about the library configuration.
 
 @copyright 2019 Dialog Semiconductor
 */

#import <CoreBluetooth/CoreBluetooth.h>
#import <Foundation/Foundation.h>

// SuotaScanner Config
/*!
 * @defined SUOTA_LIB_CONFIG_ALLOW_DIALOG_DISPLAY
 *
 * @abstract Indicates if the library should display dialogs.
 *
 * @discussion If <code>false</code>, whenever a dialog should be displayed, for example if the Bluetooth adapter is disabled, the library will only trigger the associated delegate method and let the application handle it.
 *
 */
#define SUOTA_LIB_CONFIG_ALLOW_DIALOG_DISPLAY true

// SUOTA Manager and Protocol Config
/*!
 * @defined SUOTA_LIB_CONFIG_CHECK_HEADER_CRC
 *
 * @abstract Indicates if the library should check the firmware file header CRC.
 *
 * @discussion If true calculates the firmware header CRC and compares it with the payload CRC value.
 *
 */
#define SUOTA_LIB_CONFIG_CHECK_HEADER_CRC true

// SUOTA Manager and Protocol Config
/*!
 * @defined SUOTA_LIB_CONFIG_CALCULATE_STATISTICS
 *
 * @abstract Indicates if the library should calculate statistics.
 *
 * @discussion Indicates whether the library should calculate speed statistics such at max, min, avg, block and current speed values.
 *
 */
#define SUOTA_LIB_CONFIG_CALCULATE_STATISTICS true

/*!
 * @defined SUOTA_LIB_CONFIG_UPLOAD_TIMEOUT
 *
 * @abstract Upload timeout milli seconds.
 *
 */
#define SUOTA_LIB_CONFIG_UPLOAD_TIMEOUT 30000 //ms

/*!
 * @defined SUOTA_LIB_CONFIG_AUTO_REBOOT
 *
 * @abstract Indicates if a reboot signal should be send to device after a successfull update.
 *
 * @discussion If <code>false</code> user should be promted to send the reboot signal to the device on {@link onSuccess:imageUploadElapsedSeconds:} method call.
 *
 */
#define SUOTA_LIB_CONFIG_AUTO_REBOOT true

/*!
 * @defined SUOTA_LIB_CONFIG_AUTO_DISCONNECT_IF_REBOOT_DENIED
 *
 * @abstract Indicates whether the device must be disconnected after a successfull update.
 *
 * @discussion Used in user prompt for device disconnection after a successful SUOTA update. If <code>true</code>, the device is disconnected regardless of the user answer.
 *
 */
#define SUOTA_LIB_CONFIG_AUTO_DISCONNECT_IF_REBOOT_DENIED false

/*!
 * @defined SUOTA_LIB_CONFIG_AUTO_READ_DEVICE_INFO
 *
 * @abstract Indicates whether the the device info characteristics should be read after the connection with the device.
 *
 */
#define SUOTA_LIB_CONFIG_AUTO_READ_DEVICE_INFO true

/*!
 * @defined SUOTA_LIB_CONFIG_READ_DEVICE_INFO_FIRST
 *
 * @abstract Indicates whether the the device info characteristics shall be read prior to the SUOTA info characteristics.
 *
 * @discussion This value has a meaning only if the {@link SUOTA_LIB_CONFIG_AUTO_READ_DEVICE_INFO} is <code>true</code>. The SUOTA info characteristics are read in any case.
 *
 */
#define SUOTA_LIB_CONFIG_READ_DEVICE_INFO_FIRST true

/*!
 * @defined SUOTA_LIB_CONFIG_READ_ALL_DEVICE_INFO
 *
 * @abstract Indicates whether all available device info characteristics will be read after the connection with the device.
 *
 * @discussion If <code>false</code>, only the characteristics specified in {@link DEVICE_INFO_TO_READ} are going to be read. This value has a meaning only if the {@link SUOTA_LIB_CONFIG_AUTO_READ_DEVICE_INFO} value is <code>true</code>.
 *
 */
#define SUOTA_LIB_CONFIG_READ_ALL_DEVICE_INFO false

/*!
 * @defined SUOTA_LIB_CONFIG_NOTIFY_DEVICE_INFO_READ
 *
 * @abstract Indicates whether the {@link onCharacteristicRead:characteristic:} method shall be called on each info characteristic value read.
 *
 */
#define SUOTA_LIB_CONFIG_NOTIFY_DEVICE_INFO_READ true

/*!
 * @defined SUOTA_LIB_CONFIG_NOTIFY_DEVICE_INFO_READ_COMPLETED
 *
 * @abstract Indicates whether the {@link onDeviceInfoReadCompleted:} method shall be called when all the available device info characteristics have been read.
 *
 */
#define SUOTA_LIB_CONFIG_NOTIFY_DEVICE_INFO_READ_COMPLETED true

/*!
 * @defined SUOTA_LIB_CONFIG_NOTIFY_SUOTA_LOG
 *
 * @abstract Indicates whether the {@link onSuotaLog:type:log:} method shall be called on SUOTA protocol state changes during the update procedure.
 *
 */
#define SUOTA_LIB_CONFIG_NOTIFY_SUOTA_LOG true

/*!
 * @defined SUOTA_LIB_CONFIG_NOTIFY_SUOTA_LOG_CHUNK
 *
 * @abstract Indicates whether the {@link onSuotaLog:type:log:} method shall be called on chunk sent.
 *
 */
#define SUOTA_LIB_CONFIG_NOTIFY_SUOTA_LOG_CHUNK false

/*!
 * @defined SUOTA_LIB_CONFIG_NOTIFY_SUOTA_LOG_BLOCK
 *
 * @abstract Indicates whether the {@link onSuotaLog:type:log:} method shall be called on block sent.
 *
 */
#define SUOTA_LIB_CONFIG_NOTIFY_SUOTA_LOG_BLOCK false

/*!
 * @defined SUOTA_LIB_CONFIG_NOTIFY_CHUNK_SEND
 *
 * @abstract Indicates whether the {@link onChunkSend:totalChunks:chunk:block:blockChunks:totalBlocks:} method shall be called on SUOTA chunk sent.
 *
 */
#define SUOTA_LIB_CONFIG_NOTIFY_CHUNK_SEND true

/*!
 * @defined SUOTA_LIB_CONFIG_NOTIFY_BLOCK_SENT
 *
 * @abstract Indicates whether the {@link onBlockSent:totalBlocks:} method shall be called on SUOTA block sent.
 *
 */
#define SUOTA_LIB_CONFIG_NOTIFY_BLOCK_SENT true

/*!
 * @defined SUOTA_LIB_CONFIG_NOTIFY_UPLOAD_PROGRESS
 *
 * @abstract Indicates whether the {@link onUploadProgress:} method shall be called on an update at the image upload progress.
 *
 */
#define SUOTA_LIB_CONFIG_NOTIFY_UPLOAD_PROGRESS true

/*!
 * @defined SUOTA_LIB_CONFIG_PROTOCOL_DEBUG
 *
 * @abstract Indicates whether debugging logs are going to be generated for the SUOTA protocol.
 *
 */
#define SUOTA_LIB_CONFIG_PROTOCOL_DEBUG false


// Default values
/*!
 * @defined SUOTA_LIB_DEFAULT_SCAN_TIMEOUT
 *
 * @abstract Default scan duration.
 *
 */
#define SUOTA_LIB_DEFAULT_SCAN_TIMEOUT 10000 // ms

/*!
 * @defined SUOTA_LIB_DEFAULT_FILE_LIST_HEADER_INFO
 *
 * @abstract Indicates if the header info of each firmware file found should be initialized.
 *
 */
#define SUOTA_LIB_DEFAULT_FILE_LIST_HEADER_INFO false

/*!
 * @defined SUOTA_LIB_DEFAULT_BLOCK_SIZE
 *
 * @abstract Default file block size in bytes.
 *
 */
#define SUOTA_LIB_DEFAULT_BLOCK_SIZE 240

/*!
 * @defined SUOTA_LIB_DEFAULT_CHUNK_SIZE
 *
 * @abstract Default file chunk size in bytes.
 *
 */
#define SUOTA_LIB_DEFAULT_CHUNK_SIZE 20

// Memory type
/*!
 * @defined SUOTA_LIB_DEFAULT_IMAGE_BANK
 *
 * @abstract Default memory bank.
 *
 */
#define SUOTA_LIB_DEFAULT_IMAGE_BANK IMAGE_BANK_OLDEST
/*!
 * @defined SUOTA_LIB_DEFAULT_MEMORY_TYPE
 *
 * @abstract Default memory type.
 *
 */
#define SUOTA_LIB_DEFAULT_MEMORY_TYPE MEMORY_TYPE_EXTERNAL_SPI
// SPI memory settings
/*!
 * @defined SUOTA_LIB_DEFAULT_MISO_GPIO
 *
 * @abstract Default SPI MISO value.
 *
 */
#define SUOTA_LIB_DEFAULT_MISO_GPIO 0x05
/*!
 * @defined SUOTA_LIB_DEFAULT_MOSI_GPIO
 *
 * @abstract Default SPI MOSI value.
 *
 */
#define SUOTA_LIB_DEFAULT_MOSI_GPIO 0x06
/*!
 * @defined SUOTA_LIB_DEFAULT_CS_GPIO
 *
 * @abstract Default SPI CS value.
 *
 */
#define SUOTA_LIB_DEFAULT_CS_GPIO 0x03
/*!
 * @defined SUOTA_LIB_DEFAULT_SCK_GPIO
 *
 * @abstract Default SPI SCK value.
 *
 */
#define SUOTA_LIB_DEFAULT_SCK_GPIO 0x00

// I2C memory settings
/*!
 * @defined SUOTA_LIB_DEFAULT_I2C_DEVICE_ADDRESS
 *
 * @abstract Default I2C device address.
 *
 */
#define SUOTA_LIB_DEFAULT_I2C_DEVICE_ADDRESS 0x50
/*!
 * @defined SUOTA_LIB_DEFAULT_SCL_GPIO
 *
 * @abstract Default I2C SCL GPIO value.
 *
 */
#define SUOTA_LIB_DEFAULT_SCL_GPIO 0x02
/*!
 * @defined SUOTA_LIB_DEFAULT_SDA_GPIO
 *
 * @abstract Default I2C SDA GPIO value.
 *
 */
#define SUOTA_LIB_DEFAULT_SDA_GPIO 0x03

/*!
 * @class SuotaLibConfig
 *
 * @discussion Library configuration object.
 *
 */
@interface SuotaLibConfig : NSObject

/*!
 * @property ALLOW_DIALOG_DISPLAY
 *
 * @discussion Property containing the {@link SUOTA_LIB_CONFIG_ALLOW_DIALOG_DISPLAY} value.
 */
@property (class, readonly) BOOL ALLOW_DIALOG_DISPLAY;

/*!
 * @property CHECK_HEADER_CRC
 *
 * @discussion Property containing the {@link SUOTA_LIB_CONFIG_CHECK_HEADER_CRC} value.
 */
@property (class, readonly) BOOL CHECK_HEADER_CRC;
/*!
 * @property CALCULATE_STATISTICS
 *
 * @discussion Property containing the {@link SUOTA_LIB_CONFIG_CALCULATE_STATISTICS} value.
 */
@property (class, readonly) BOOL CALCULATE_STATISTICS;
/*!
 * @property UPLOAD_TIMEOUT
 *
 * @discussion Property containing the {@link SUOTA_LIB_CONFIG_UPLOAD_TIMEOUT} value.
 */
@property (class, readonly) int UPLOAD_TIMEOUT;
/*!
 * @property AUTO_REBOOT
 *
 * @discussion Property containing the {@link SUOTA_LIB_CONFIG_AUTO_REBOOT} value.
 */
@property (class, readonly) BOOL AUTO_REBOOT;
/*!
 * @property AUTO_DISCONNECT_IF_REBOOT_DENIED
 *
 * @discussion Property containing the {@link SUOTA_LIB_CONFIG_AUTO_DISCONNECT_IF_REBOOT_DENIED} value.
 */
@property (class, readonly) BOOL AUTO_DISCONNECT_IF_REBOOT_DENIED;
/*!
 * @property AUTO_READ_DEVICE_INFO
 *
 * @discussion Property containing the {@link SUOTA_LIB_CONFIG_AUTO_READ_DEVICE_INFO} value.
 */
@property (class, readonly) BOOL AUTO_READ_DEVICE_INFO;
/*!
 * @property READ_DEVICE_INFO_FIRST
 *
 * @discussion Property containing the {@link SUOTA_LIB_CONFIG_READ_DEVICE_INFO_FIRST} value.
 */
@property (class, readonly) BOOL READ_DEVICE_INFO_FIRST;
/*!
 * @property READ_ALL_DEVICE_INFO
 *
 * @discussion Property containing the {@link SUOTA_LIB_CONFIG_READ_ALL_DEVICE_INFO} value.
 */
@property (class, readonly) BOOL READ_ALL_DEVICE_INFO;
/*!
 * @property NOTIFY_DEVICE_INFO_READ
 *
 * @discussion Property containing the {@link SUOTA_LIB_CONFIG_NOTIFY_DEVICE_INFO_READ} value.
 */
@property (class, readonly) BOOL NOTIFY_DEVICE_INFO_READ;
/*!
 * @property NOTIFY_DEVICE_INFO_READ_COMPLETED
 *
 * @discussion Property containing the {@link SUOTA_LIB_CONFIG_NOTIFY_DEVICE_INFO_READ_COMPLETED} value.
 */
@property (class, readonly) BOOL NOTIFY_DEVICE_INFO_READ_COMPLETED;
/*!
 * @property NOTIFY_SUOTA_LOG
 *
 * @discussion Property containing the {@link SUOTA_LIB_CONFIG_NOTIFY_SUOTA_LOG} value.
 */
@property (class, readonly) BOOL NOTIFY_SUOTA_LOG;
/*!
 * @property NOTIFY_SUOTA_LOG_CHUNK
 *
 * @discussion Property containing the {@link SUOTA_LIB_CONFIG_NOTIFY_SUOTA_LOG_CHUNK} value.
 */
@property (class, readonly) BOOL NOTIFY_SUOTA_LOG_CHUNK;
/*!
 * @property NOTIFY_SUOTA_LOG_BLOCK
 *
 * @discussion Property containing the {@link SUOTA_LIB_CONFIG_NOTIFY_SUOTA_LOG_BLOCK} value.
 */
@property (class, readonly) BOOL NOTIFY_SUOTA_LOG_BLOCK;
/*!
 * @property NOTIFY_CHUNK_SEND
 *
 * @discussion Property containing the {@link SUOTA_LIB_CONFIG_NOTIFY_CHUNK_SEND} value.
 */
@property (class, readonly) BOOL NOTIFY_CHUNK_SEND;
/*!
 * @property NOTIFY_BLOCK_SENT
 *
 * @discussion Property containing the {@link SUOTA_LIB_CONFIG_NOTIFY_BLOCK_SENT} value.
 */
@property (class, readonly) BOOL NOTIFY_BLOCK_SENT;
/*!
 * @property NOTIFY_UPLOAD_PROGRESS
 *
 * @discussion Property containing the {@link SUOTA_LIB_CONFIG_NOTIFY_UPLOAD_PROGRESS} value.
 */
@property (class, readonly) BOOL NOTIFY_UPLOAD_PROGRESS;
/*!
 * @property PROTOCOL_DEBUG
 *
 * @discussion Property containing the {@link SUOTA_LIB_CONFIG_PROTOCOL_DEBUG} value.
 */
@property (class, readonly) BOOL PROTOCOL_DEBUG;
/*!
 * @property DEVICE_INFO_TO_READ
 *
 * @discussion Array containing the {@link CBUUID} of the necessary device info characteristics.
 */
@property (class, readonly) NSArray<CBUUID*>* DEVICE_INFO_TO_READ;

/*!
 * @property DEFAULT_SCAN_TIMEOUT
 *
 * @discussion Property containing the {@link SUOTA_LIB_DEFAULT_SCAN_TIMEOUT} value.
 */
@property (class, readonly) int DEFAULT_SCAN_TIMEOUT;

/*!
 * @property DEFAULT_FIRMWARE_PATH
 *
 * @discussion Property containing the default path that contains the firmware.
 */
@property (class, readonly) NSString* DEFAULT_FIRMWARE_PATH;

/*!
 * @property FILE_LIST_HEADER_INFO
 *
 * @discussion Property containing the {@link SUOTA_LIB_DEFAULT_FILE_LIST_HEADER_INFO} value.
 */
@property (class, readonly) BOOL FILE_LIST_HEADER_INFO;

/*!
 * @property DEFAULT_BLOCK_SIZE
 *
 * @discussion Property containing the {@link SUOTA_LIB_DEFAULT_BLOCK_SIZE} value.
 */
@property (class, readonly) int DEFAULT_BLOCK_SIZE;
/*!
 * @property DEFAULT_CHUNK_SIZE
 *
 * @discussion Property containing the {@link SUOTA_LIB_DEFAULT_CHUNK_SIZE} value.
 */
@property (class, readonly) int DEFAULT_CHUNK_SIZE;

/*!
 * @property DEFAULT_IMAGE_BANK
 *
 * @discussion Property containing the {@link SUOTA_LIB_DEFAULT_IMAGE_BANK} value.
 */
@property (class, readonly) uint8_t DEFAULT_IMAGE_BANK;

/*!
 * @property DEFAULT_MEMORY_TYPE
 *
 * @discussion Property containing the {@link SUOTA_LIB_DEFAULT_MEMORY_TYPE} value.
 */
@property (class, readonly) uint8_t DEFAULT_MEMORY_TYPE;

/*!
 * @property DEFAULT_MISO_GPIO
 *
 * @discussion Property containing the {@link SUOTA_LIB_DEFAULT_MISO_GPIO} value.
 */
@property (class, readonly) uint8_t DEFAULT_MISO_GPIO;
/*!
 * @property DEFAULT_MOSI_GPIO
 *
 * @discussion Property containing the {@link SUOTA_LIB_DEFAULT_MOSI_GPIO} value.
 */
@property (class, readonly) uint8_t DEFAULT_MOSI_GPIO;
/*!
 * @property DEFAULT_CS_GPIO
 *
 * @discussion Property containing the {@link SUOTA_LIB_DEFAULT_CS_GPIO} value.
 */
@property (class, readonly) uint8_t DEFAULT_CS_GPIO;
/*!
 * @property DEFAULT_SCK_GPIO
 *
 * @discussion Property containing the {@link SUOTA_LIB_DEFAULT_SCK_GPIO} value.
 */
@property (class, readonly) uint8_t DEFAULT_SCK_GPIO;

/*!
 * @property DEFAULT_I2C_DEVICE_ADDRESS
 *
 * @discussion Property containing the {@link SUOTA_LIB_DEFAULT_I2C_DEVICE_ADDRESS} value.
 */
@property (class, readonly) uint8_t DEFAULT_I2C_DEVICE_ADDRESS;
/*!
 * @property DEFAULT_SCL_GPIO
 *
 * @discussion Property containing the {@link SUOTA_LIB_DEFAULT_SCL_GPIO} value.
 */
@property (class, readonly) uint8_t DEFAULT_SCL_GPIO;
/*!
 * @property DEFAULT_SDA_GPIO
 *
 * @discussion Property containing the {@link SUOTA_LIB_DEFAULT_SDA_GPIO} value.
 */
@property (class, readonly) uint8_t DEFAULT_SDA_GPIO;

@end
