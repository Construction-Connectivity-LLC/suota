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
 @header SuotaManager.h
 @brief Header file for the SuotaManager class.
 
 This header file contains method and property declaration for the SuotaManager class. It also contains the declaration for SuotaManagerDelegate protocol.
 
 @copyright 2019 Dialog Semiconductor
 */

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <UIKit/UIKIt.h>
#import "SuotaProfile.h"

@class DeviceInfo;
@class GattOperation;
@class SendChunkOperation;
@class SuotaBluetoothManager;
@class SuotaFile;
@class SuotaInfo;
@class SuotaProtocol;

enum SuotaLogType {
    INFO,
    BLOCK,
    CHUNK,
};

/*!
 *  @protocol SuotaManagerDelegate
 *
 *  @discussion The {@link SuotaManager} delegate must adopt the <code>SuotaManagerDelegate</code> protocol. The methods allow for information on the SUOTA process.
 *
 */
@protocol SuotaManagerDelegate <NSObject>

@required

/*!
 * @method onConnectionStateChange:
 *
 * @param newStatus the new connection status. Status codes can be found at {@link SuotaManagerStatus}.
 *
 * @discussion Triggered every time the connection state changes.
 */
- (void) onConnectionStateChange:(enum SuotaManagerStatus)newStatus;

@required

/*!
 * @method onServicesDiscovered
 *
 * @discussion Triggered on service discovery.
 */
- (void) onServicesDiscovered;

@required

/*!
 * @method onCharacteristicRead:characteristic:
 *
 * @param characteristicGroup The current characteristic group. Groups can be found at {@link CharacteristicGroup}.
 * @param characteristic The characteristic.
 *
 * @discussion Triggered on characteristic read.
 */
- (void) onCharacteristicRead:(enum CharacteristicGroup)characteristicGroup characteristic:(CBCharacteristic*)characteristic;

@required

/*!
 * @method onDeviceInfoReadCompleted:
 *
 * @param status {@link DeviceInfoReadStatus} status. Indicates if there is actually info read: {@link SUCCESS}, or there was no available device info to read at all {@link NO_DEVICE_INFO}.
 *
 * @discussion Triggered when all device info has been read.
 */
- (void) onDeviceInfoReadCompleted:(enum DeviceInfoReadStatus)status;

@required

/*!
 * @method onDeviceReady
 *
 * @discussion Triggered when all available SUOTA info has been read. If {@link AUTO_READ_DEVICE_INFO} is set to <code>true</code>, the method indicates that device info has also been read.
 */
- (void) onDeviceReady;

@required

/*!
 * @method onSuotaLog:type:log:
 *
 * @param state The current {@link SuotaProtocolState}.
 * @param type The log type.
 * @param log The associated status update message.
 *
 * @discussion Triggered if {@link NOTIFY_SUOTA_STATUS} is <code>true</code>.
 */
- (void) onSuotaLog:(enum SuotaProtocolState)state type:(enum SuotaLogType)type log:(NSString*)log;

@required

/*!
 * @method onChunkSend:totalChunks:chunk:block:blockChunks:totalBlocks:
 *
 * @param chunkCount Chunk count of total chunks.
 * @param totalChunks Total chunks.
 * @param chunk Chunk count of current block.
 * @param block Block count.
 * @param blockChunks Total chunks in current block.
 * @param totalBlocks Total blocks.
 *
 * @discussion Triggered on chunk sent if {@link NOTIFY_CHUNK_SEND} is <code>true</code>.
 */
- (void) onChunkSend:(int)chunkCount totalChunks:(int)totalChunks chunk:(int)chunk block:(int)block blockChunks:(int)blockChunks totalBlocks:(int)totalBlocks;

@required

/*!
 * @method onBlockSent:
 *
 * @param block Block count.
 * @param totalBlocks Total blocks.
 *
 * @discussion Triggered after a successful block transfer.
 */
- (void) onBlockSent:(int)block totalBlocks:(int)totalBlocks;

@required

/*!
 * @method updateSpeedStatistics:max:min:avg:
 *
 * @param current Current block speed Bps.
 * @param max Maximum transfer speed in Bps.
 * @param min Minimum transfer speed in Bps.
 * @param avg Average transfer speed in Bps.
 *
 * @discussion Triggered every 500 ms if {@link CALCULATE_STATISTICS} is <code>true</code>.
 */
- (void) updateSpeedStatistics:(double)current max:(double)max min:(double)min avg:(double)avg;

@required

/*!
 * @method updateCurrentSpeed:
 *
 * @param currentSpeed Bytes sent per second.
 *
 * @discussion Triggered every 1000 ms if {@link CALCULATE_STATISTICS} is <code>true</code>. It is about the current bytes sent per second and not an average value.
 */
- (void) updateCurrentSpeed:(double)currentSpeed;

@required

/*!
 * @method onUploadProgress:
 *
 * @param percent The percent of the firmware file already sent to device.
 *
 * @discussion Triggered if {@link NOTIFY_UPLOAD_PROGRESS} is <code>true</code>.
 */
- (void) onUploadProgress:(float)percent;

@required

/*!
 * @method onSuccess:imageUploadElapsedSeconds:
 *
 * @param totalElapsedSeconds Total elapsed time during SUOTA protocol execution.
 * @param imageUploadElapsedSeconds Elapsed time during image upload.
 *
 * @discussion Triggered after the SUOTA process has finished successfully. In case that the elapsed time can not be calculated, the time parameter values equal to <code>-1</code>.
 */
- (void) onSuccess:(double)totalElapsedSeconds imageUploadElapsedSeconds:(double)imageUploadElapsedSeconds;

@required

/*!
 * @method onFailure:
 *
 * @param errorCode Reason caused the failure. Error codes can be found at {@link SuotaErrors} and {@link ApplicationErrors}.
 *
 * @discussion Triggered in case of an unexpected event occurs.
 *
 */
- (void) onFailure:(int)errorCode;

@required

/*!
 * @method onRebootSent
 *
 * @discussion Triggered when the reboot signal is sent to the device.
 */
- (void) onRebootSent;

@end

/*!
 * @class SuotaManager
 *
 * @discussion This class handles the SUOTA process for a BLE device.
 *
 */
@interface SuotaManager : NSObject <CBPeripheralDelegate>

enum ManagerState {
    DEVICE_DISCONNECTED,
    DEVICE_CONNECTING,
    DEVICE_CONNECTED,
};

@property CBPeripheral* peripheral;
@property (weak) id<SuotaManagerDelegate> suotaManagerDelegate;
@property SuotaBluetoothManager* bluetoothManager;
@property enum ManagerState state;
@property SuotaProtocol* suotaProtocol;
@property (weak) UIViewController* suotaViewController;
@property NSMutableArray<SendChunkOperation*>* sendChunkOperationArray;
@property BOOL sendChunkOperationPending;
@property BOOL rebootSent;

// SUOTA configuration
/*!
 *  @property suotaFile
 *
 *  @discussion The firmware file used during the update.
 *
 */
@property (nonatomic) SuotaFile* suotaFile;
@property int blockSize;
@property int chunkSize;
@property uint8_t imageBank;
@property uint8_t memoryType;
// SPI
@property uint8_t misoGpio;
@property uint8_t mosiGpio;
@property uint8_t csGpio;
@property uint8_t sckGpio;
//I2C
@property uint16_t i2cDeviceAddress;
@property uint8_t sclGpio;
@property uint8_t sdaGpio;

@property CBService* suotaService;
@property CBCharacteristic* memDevCharacteristic;
@property CBCharacteristic* gpioMapCharacteristic;
@property CBCharacteristic* memoryInfoCharacteristic;
@property CBCharacteristic* patchLengthCharacteristic;
@property CBCharacteristic* patchDataCharacteristic;
@property CBCharacteristic* serviceStatusCharacteristic;
@property CBCharacteristic* serviceStatusClientConfigDescriptor;

// SUOTA Info
@property CBCharacteristic* suotaVersionCharacteristic;
@property CBCharacteristic* patchDataSizeCharacteristic;
@property CBCharacteristic* mtuCharacteristic;
@property CBCharacteristic* l2capPsmCharacteristic;

/*!
 *  @property suotaVersion
 *
 *  @discussion SUOTA version characteristic value. Has a default value of 0 if the characteristic hasn't been read.
 *
 */
@property int suotaVersion;

/*!
 *  @property mtu
 *
 *  @discussion MTU characteristic value. Has a default value of 23 if the characteristic hasn't been read.
 *
 */
@property int mtu;

/*!
 *  @property patchDataSize
 *
 *  @discussion Patch data size characteristic value. Has a default value of 20 if the characteristic hasn't been read.
 *
 */
@property int patchDataSize;


/*!
 *  @property l2capPsm
 *
 *  @discussion L2CAP characteristic value. Has a default value of 0 if the characteristic hasn't been read.
 *
 */
@property int l2capPsm;

/*!
 *  @property suotaVersionRead
 *
 *  @discussion Checks if the SUOTA version characteristic has been read.
 *
 */
@property BOOL suotaVersionRead;

/*!
 *  @property patchDataSizeRead
 *
 *  @discussion Checks if the patch data size characteristic has been read.
 *
 */
@property BOOL patchDataSizeRead;

/*!
 *  @property mtuRead
 *
 *  @discussion Checks if the mtu characteristic has been read.
 *
 */
@property BOOL mtuRead;

/*!
 *  @property l2capPsmRead
 *
 *  @discussion Checks if the L2CAP characteristic has been read.
 *
 */
@property BOOL l2capPsmRead;

// Device Info
@property CBService* deviceInfoService;
@property CBCharacteristic* manufacturerNameCharacteristic;
@property CBCharacteristic* modelNumberCharacteristic;
@property CBCharacteristic* serialNumberCharacteristic;
@property CBCharacteristic* hardwareRevisionCharacteristic;
@property CBCharacteristic* firmwareRevisionCharacteristic;
@property CBCharacteristic* softwareRevisionCharacteristic;
@property CBCharacteristic* systemIdCharacteristic;
@property CBCharacteristic* ieee11073Characteristic;
@property CBCharacteristic* pnpIdCharacteristic;


/*!
 *  @property manufacturerName
 *
 *  @discussion Manufacturer name characteristic value. Has a nil value if the characteristic hasn't been read.
 *
 */
@property NSString* manufacturerName;

/*!
 *  @property modelNumber
 *
 *  @discussion Model number characteristic value. Has a nil value if the characteristic hasn't been read.
 *
 */
@property NSString* modelNumber;

/*!
 *  @property serialNumber
 *
 *  @discussion Serial number characteristic value. Has a nil value if the characteristic hasn't been read.
 *
 */
@property NSString* serialNumber;

/*!
 *  @property hardwareRevision
 *
 *  @discussion Hardware revision characteristic value. Has a nil value if the characteristic hasn't been read.
 *
 */
@property NSString* hardwareRevision;

/*!
 *  @property firmwareRevision
 *
 *  @discussion Firmware revision characteristic value. Has a nil value if the characteristic hasn't been read.
 *
 */
@property NSString* firmwareRevision;

/*!
 *  @property softwareRevision
 *
 *  @discussion Software revision characteristic value. Has a nil value if the characteristic hasn't been read.
 *
 */
@property NSString* softwareRevision;

/*!
 *  @property systemId
 *
 *  @discussion Last read value of system ID characteristic.
 *
 */
@property NSData* systemId;

/*!
 *  @property ieee11073
 *
 *  @discussion Last read value of IEEE 11073 characteristic.
 *
 */
@property NSData* ieee11073;

/*!
 *  @property pnpId
 *
 *  @discussion Last read value of PNP ID characteristic.
 *
 */
@property NSData* pnpId;

/*!
 *  @property suotaInfoMap
 *
 *  @discussion An {@link NSDictionary} of the SUOTA info characteristics. Dictionary key is the characteristic {@link CBUUID} and value is the {@link CBCharacteristic} object.
 *
 */
@property NSMutableDictionary<CBUUID*, CBCharacteristic*>* suotaInfoMap;
/*!
 *  @property deviceInfoMap
 *
 *  @discussion An {@link NSDictionary} of the device info characteristics. Dictionary key is the characteristic {@link CBUUID} and value is the {@link CBCharacteristic} object.
 *
 */
@property NSMutableDictionary<CBUUID*, CBCharacteristic*>* deviceInfoMap;
@property BOOL isSuotaInfoReadGroupPending;
@property BOOL isDeviceInfoReadGroupPending;
@property int totalSuotaInfo;
@property int totalDeviceInfo;
@property (class, readonly) NSArray<CBUUID*>* suotaInfoUuids;
@property (class, readonly) NSArray<CBUUID*>* deviceInfoUuids;

/*!
 * @method initWithPeripheral:suotaManagerDelegate:
 *
 * @param peripheral The BLE device to perform SUOTA.
 * @param suotaManagerDelegate The {@link SuotaManagerDelegate} delegate object that will receive {@link SuotaManager} events.
 *
 * @discussion Initializes a {@link SuotaManager} object with the given parameters.
 */
- (instancetype) initWithPeripheral:(CBPeripheral*)peripheral suotaManagerDelegate:(id<SuotaManagerDelegate>)suotaManagerDelegate;

/*!
 *  @method deviceName
 *
 *  @discussion The name of the BLE device.
 *
 */
- (NSString*) deviceName;

/*!
 *  @method avg
 *
 *  @discussion The avg value of speed until now. Returns <code>-1</code> if the configuration has disabled calculating statistics.
 *
 */
- (double) avg;

/*!
 *  @method max
 *
 *  @discussion The max value of speed until now. Returns <code>-1</code> if the configuration has disabled calculating statistics.
 *
 */
- (double) max;

/*!
 *  @method min
 *
 *  @discussion The min value of speed until now. Returns <code>-1</code> if the configuration has disabled calculating statistics.
 *
 */
- (double) min;

/*!
 * @method formatedDeviceInfoMap
 *
 * @discussion Returns an {@link NSDictionary} object of the device info read. The dictionary key is the corresponding {@link CBUUID} and the value is the characteristic value parsed to string.
 *
 * @return The {@link NSDictionary} of the device info if it has been read, otherwise an empty {@link NSDictionary} object.
 */
- (NSDictionary<CBUUID*, NSString*>*) formattedDeviceInfoMap;

/*!
 * @method formatedSuotaInfoMap
 *
 * @discussion Returns an {@link NSDictionary} of the SUOTA info read. Dictionary key is the corresponding {@link CBUUID} and value is the characteristic value parsed to string.
 *
 * @return The {@link NSDictionary} of the SUOTA info if it has been read, otherwise an empty {@link NSDictionary} object.
 */
- (NSDictionary<CBUUID*, NSString*>*) formattedSuotaInfoMap;

/*!
 * @method readCharacteristic
 *
 * @param uuid The characteristic UUID.
 *
 * @discussion Reads the characteristic with the specified UUID.
 *
 * @throws {@link NSException} if the requested characteristic is not available or the BLE device is disconnected.
 *
 */
- (void) readCharacteristic:(CBUUID*)uuid;

/*!
 * @method hasDeviceInfo
 *
 * @param uuid UUID of the device info characteristic, nil for the device info service
 *
 * @discussion Checks device information service availability.
 *
 */
- (BOOL) hasDeviceInfo:(CBUUID*)uuid;

/*!
 * @method readManufacturer
 *
 * @discussion Reads the manufacturer characteristic.
 *
 * @throws {@link NSException} if there is not a connection with a BLE device,
 * or the requested characteristic is not available.
 */
- (void) readManufacturer;

/*!
 * @method readModelNumber
 *
 * @discussion Reads the model number characteristic.
 *
 * @throws {@link NSException} if there is not a connection with a BLE device,
 * or the requested characteristic is not available.
 */
- (void) readModelNumber;

/*!
 * @method readSerialNumber
 *
 * @discussion Reads the serial number characteristic.
 *
 * @throws {@link NSException} if there is not a connection with a BLE device,
 * or the requested characteristic is not available.
 */
- (void) readSerialNumber;

/*!
 * @method readHardwareRevision
 *
 * @discussion Reads the hardware revision characteristic.
 *
 * @throws {@link NSException} if there is not a connection with a BLE device,
 * or the requested characteristic is not available.
 */
- (void) readHardwareRevision;

/*!
 * @method readFirmwareRevision
 *
 * @discussion Reads the firmware revision characteristic.
 *
 * @throws {@link NSException} if there is not a connection with a BLE device,
 * or the requested characteristic is not available.
 */
- (void) readFirmwareRevision;

/*!
 * @method readSoftwareRevision
 *
 * @discussion Reads the software revision characteristic.
 *
 * @throws {@link NSException} if there is not a connection with a BLE device,
 * or the requested characteristic is not available.
 */
- (void) readSoftwareRevision;

/*!
 * @method readSystemId
 *
 * @discussion Reads the system ID characteristic.
 *
 * @throws {@link NSException} if there is not a connection with a BLE device,
 * or the requested characteristic is not available.
 */
- (void) readSystemId;

/*!
 * @method readIeee11073
 *
 * @discussion Reads the IEEE 11073 characteristic.
 *
 * @throws {@link NSException} if there is not a connection with a BLE device,
 * or the requested characteristic is not available.
 */
- (void) readIeee11073;

/*!
 * @method readPnpId
 *
 * @discussion Reads the PNP ID characteristic.
 *
 * @throws {@link NSException} if there is not a connection with a BLE device,
 * or the requested characteristic is not available.
 */
- (void) readPnpId;

/*!
 * @method readSuotaVersion
 *
 * @discussion Reads the SUOTA version characteristic.
 *
 * @throws {@link NSException} if there is not a connection with a BLE device,
 * or the requested characteristic is not available.
 */
- (void) readSuotaVersion;

/*!
 * @method readPatchDataSize
 *
 * @discussion Reads the patch data size characteristic.
 *
 * @throws {@link NSException} if there is not a connection with a BLE device,
 * or the requested characteristic is not available.
 */
- (void) readPatchDataSize;

/*!
 * @method readMtu
 *
 * @discussion Reads the MTU characteristic.
 *
 * @throws {@link NSException} if there is not a connection with a BLE device,
 * or the requested characteristic is not available.
 */
- (void) readMtu;

/*!
 * @method readL2capPsm
 *
 * @discussion Reads the L2CAP characteristic.
 *
 * @throws {@link NSException} if there is not a connection with a BLE device,
 * or the requested characteristic is not available.
 */
- (void) readL2capPsm;

/*!
 * @method readDeviceInfo
 *
 * @discussion Queue characteristic read commands for reading the device info. The commands contain either all the available characteristics
 * or the specified device at {@link DEVICE_INFO_TO_READ}.
 *
 * @throws {@link NSException} if it is not connected to the device.
 */
- (void) readDeviceInfo;

/*!
 * @method connect:
 *
 * @discussion Connects to the {@link CBPeripheral} device passed as constructor param.
 */
- (void) connect;

/*!
 * @method initializeSuota
 *
 * @discussion Initializes the SUOTA protocol settings using default values. If a SUOTA process is already running this method does nothing.
 *
 * @see initializeSuota:misoGpio:mosiGpio:csGpio:sckGpio:imageBank:
 * @see initializeSuota:i2cAddress:sclGpio:sdaGpio:imageBank:
 * @see initializeSuota:blockSize:misoGpio:mosiGpio:csGpio:sckGpio:imageBank:
 * @see initializeSuota:blockSize:i2cAddress:sclGpio:sdaGpio:imageBank:
 */
- (void) initializeSuota;

/*!
 * @method initializeSuota:misoGpio:mosiGpio:csGpio:sckGpio:imageBank:
 *
 * @param blockSize Selected block size.
 * @param misoGpio Selected miso gpio.
 * @param mosiGpio Selected mosi gpio.
 * @param csGpio Selected cs gpio.
 * @param sckGpio Selected sck gpio.
 * @param imageBank Selected image bank.
 *
 * @discussion Initializes the SUOTA protocol settings using the values passed as arguments. Use this when the memory type is SPI. If a SUOTA process is already running this method does nothing.
 *
 * @see initializeSuota
 * @see initializeSuota:i2cAddress:sclGpio:sdaGpio:imageBank:
 * @see initializeSuota:blockSize:misoGpio:mosiGpio:csGpio:sckGpio:imageBank:
 * @see initializeSuota:blockSize:i2cAddress:sclGpio:sdaGpio:imageBank:
 */
- (void) initializeSuota:(int)blockSize misoGpio:(int)misoGpio mosiGpio:(int)mosiGpio csGpio:(int)csGpio sckGpio:(int)sckGpio imageBank:(int)imageBank;

/*!
 * @method initializeSuota:i2cAddress:sclGpio:sdaGpio:imageBank:
 *
 * @param blockSize Selected block size.
 * @param i2cAddress Selected i2c address.
 * @param sclGpio Selected scl gpio.
 * @param sdaGpio Selected sda gpio.
 * @param imageBank Selected image bank.
 *
 * @see initializeSuota
 * @see initializeSuota:misoGpio:mosiGpio:csGpio:sckGpio:imageBank:
 * @see initializeSuota:blockSize:misoGpio:mosiGpio:csGpio:sckGpio:imageBank:
 * @see initializeSuota:blockSize:i2cAddress:sclGpio:sdaGpio:imageBank:
 * @discussion  Initializes the SUOTA protocol settings using the values passed as arguments. Use this when the memory type is I2C. If a SUOTA process is already running this method does nothing.
 */
- (void) initializeSuota:(int)blockSize i2cAddress:(int)i2cAddress sclGpio:(int)sclGpio sdaGpio:(int)sdaGpio imageBank:(int)imageBank;

/*!
 @method initializeSuota:blockSize:misoGpio:mosiGpio:csGpio:sckGpio:imageBank:
 *
 * @param firmware Firmware to used for the update.
 * @param blockSize Selected block size.
 * @param misoGpio Selected miso gpio.
 * @param mosiGpio Selected mosi gpio.
 * @param csGpio Selected cs gpio.
 * @param sckGpio Selected sck gpio.
 * @param imageBank Selected image bank.
 *
 * @discussion Initializes the SUOTA protocol settings using the values passed as arguments. Use this when the memory type is SPI. If a SUOTA process is already running this method does nothing.
 *
 * @see initializeSuota
 * @see initializeSuota:misoGpio:mosiGpio:csGpio:sckGpio:imageBank:
 * @see initializeSuota:i2cAddress:sclGpio:sdaGpio:imageBank:
 * @see initializeSuota:blockSize:i2cAddress:sclGpio:sdaGpio:imageBank:
 */
- (void) initializeSuota:(SuotaFile*)firmware blockSize:(int)blockSize misoGpio:(int)misoGpio mosiGpio:(int)mosiGpio csGpio:(int)csGpio sckGpio:(int)sckGpio imageBank:(int)imageBank;

/*!
 @method initializeSuota:blockSize:i2cAddress:sclGpio:sdaGpio:imageBank:
 *
 * @param firmware Firmware to used for the update.
 * @param blockSize Selected block size.
 * @param i2cAddress Selected i2c address.
 * @param sclGpio Selected scl gpio.
 * @param sdaGpio Selected sda gpio.
 * @param imageBank Selected image bank.
 *
 * @discussion Initializes the SUOTA protocol settings using the values passed as arguments. Use this when the memory type is I2C. If a SUOTA process is already running this method does nothing.
 *
 * @see initializeSuota
 * @see initializeSuota:misoGpio:mosiGpio:csGpio:sckGpio:imageBank:
 * @see initializeSuota:i2cAddress:sclGpio:sdaGpio:imageBank:
 * @see initializeSuota:blockSize:misoGpio:mosiGpio:csGpio:sckGpio:imageBank:
 */
- (void) initializeSuota:(SuotaFile*)firmware blockSize:(int)blockSize i2cAddress:(int)i2cAddress sclGpio:(int)sclGpio sdaGpio:(int)sdaGpio imageBank:(int)imageBank;

/*!
 * @method startUpdate
 *
 * @discussion This method actually starts SuotaProtocol.
 * Make sure to call this only if you have successfully connected a BLE device first.
 * Otherwise this method does nothing.
 */
- (void) startUpdate;

/*!
 * @method disconnect
 *
 * @discussion Disconnects from the connected BLE device.
 */
- (void) disconnect;

/*!
 * @method destroy
 *
 * @discussion Cleans up everything needed.
 */
- (void) destroy;
- (int) memoryDevice;
- (int) gpioMap;
- (int) spiGpioMap;
- (int) i2cGpioMap;
- (void) close;
- (void) enqueueSendChunkOperation:(SendChunkOperation*)sendChunkOperation;
- (void) executeOperation:(GattOperation*)gattOperation;
- (void) executeOperationArray:(NSArray<GattOperation*>*)gattOperationArray;

- (void) onSuotaProtocolSuccess;
- (void) onServicesDiscovered:(NSArray<CBService*>*)services;
- (void) onCharacteristicsDiscovered:(CBService*)service;
- (void) onDescriptorsDiscovered:(CBCharacteristic*)characteristic;
- (void) onCharacteristicRead:(CBCharacteristic*)characteristic;
- (void) onCharacteristicWrite:(CBCharacteristic*)characteristic;
- (void) onCharacteristicChanged:(CBCharacteristic*)characteristic;
- (void) onDescriptorWrite:(CBCharacteristic*)characteristic;

@end
