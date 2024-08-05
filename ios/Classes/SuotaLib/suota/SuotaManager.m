/*
 *******************************************************************************
 *
 * Copyright (C) 2019-2020 Dialog Semiconductor.
 * This computer program includes Confidential, Proprietary Information
 * of Dialog Semiconductor. All Rights Reserved.
 *
 *******************************************************************************
 */

#import "SuotaManager.h"
#import "GattOperation.h"
#import "SendChunkOperation.h"
#import "SuotaBluetoothManager.h"
#import "SuotaFile.h"
#import "SuotaProfile.h"
#import "SuotaProtocol.h"
#import "SuotaLibConfig.h"
#import "SuotaLibLog.h"
#import "SuotaUtils.h"

@implementation SuotaManager {
    BOOL pendingConnection;
}

static NSString* const TAG = @"SuotaManager";
static NSArray<CBUUID*>* suotaInfoUuids;
static NSArray<CBUUID*>* deviceInfoUuids;

+ (void) initialize {
    if (self != SuotaManager.class)
        return;

    suotaInfoUuids = @[
            SuotaProfile.SUOTA_VERSION_UUID,
            SuotaProfile.SUOTA_PATCH_DATA_CHAR_SIZE_UUID,
            SuotaProfile.SUOTA_MTU_UUID,
            SuotaProfile.SUOTA_L2CAP_PSM_UUID
    ];

    deviceInfoUuids = @[
            SuotaProfile.CHARACTERISTIC_MANUFACTURER_NAME_STRING,
            SuotaProfile.CHARACTERISTIC_MODEL_NUMBER_STRING,
            SuotaProfile.CHARACTERISTIC_SERIAL_NUMBER_STRING,
            SuotaProfile.CHARACTERISTIC_HARDWARE_REVISION_STRING,
            SuotaProfile.CHARACTERISTIC_FIRMWARE_REVISION_STRING,
            SuotaProfile.CHARACTERISTIC_SOFTWARE_REVISION_STRING,
            SuotaProfile.CHARACTERISTIC_SYSTEM_ID,
            SuotaProfile.CHARACTERISTIC_IEEE_11073,
            SuotaProfile.CHARACTERISTIC_PNP_ID
    ];
}

+ (NSArray<CBUUID*>*) suotaInfoUuids {
    return suotaInfoUuids;
}

+ (NSArray<CBUUID*>*) deviceInfoUuids {
    return deviceInfoUuids;
}

- (instancetype) init {
    self = [super init];
    if (!self)
        return nil;

    self.state = DEVICE_DISCONNECTED;
    self.bluetoothManager = SuotaBluetoothManager.instance;
    
    // SUOTA configuration
    self.blockSize = SuotaLibConfig.DEFAULT_BLOCK_SIZE;
    self.chunkSize = SuotaLibConfig.DEFAULT_CHUNK_SIZE;
    self.imageBank = SuotaLibConfig.DEFAULT_IMAGE_BANK;
    self.memoryType = SuotaLibConfig.DEFAULT_MEMORY_TYPE;
    // SPI
    self.misoGpio = SuotaLibConfig.DEFAULT_MISO_GPIO;
    self.mosiGpio = SuotaLibConfig.DEFAULT_MOSI_GPIO;
    self.csGpio = SuotaLibConfig.DEFAULT_CS_GPIO;
    self.sckGpio = SuotaLibConfig.DEFAULT_SCK_GPIO;
    // I2C
    self.i2cDeviceAddress = SuotaLibConfig.DEFAULT_I2C_DEVICE_ADDRESS;
    self.sclGpio = SuotaLibConfig.DEFAULT_SCL_GPIO;
    self.sdaGpio = SuotaLibConfig.DEFAULT_SDA_GPIO;
    
    self.mtu = SuotaProfile.DEFAULT_MTU;
    self.patchDataSize = SuotaLibConfig.DEFAULT_CHUNK_SIZE;
    
    self.suotaInfoMap = [NSMutableDictionary dictionary];
    self.deviceInfoMap = [NSMutableDictionary dictionary];
    
    self.sendChunkOperationArray = [NSMutableArray array];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onBluetoothUpdatedState:) name:SuotaBluetoothManagerUpdatedState object:self.bluetoothManager];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onDeviceDisconnection:) name:SuotaBluetoothManagerConnectionFailed object:self.bluetoothManager];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onDeviceConnected:) name:SuotaBluetoothManagerDeviceConnected object:self.bluetoothManager];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onDeviceDisconnection:) name:SuotaBluetoothManagerDeviceDisconnected object:self.bluetoothManager];
    
    return self;
}

- (instancetype) initWithPeripheral:(CBPeripheral*)peripheral suotaManagerDelegate:(id<SuotaManagerDelegate>)suotaManagerDelegate {
    self = [self init];
    if (!self)
        return nil;
    
    self.peripheral = [self.bluetoothManager retrievePeripheralWithIdentifier:peripheral.identifier];
    self.suotaManagerDelegate = suotaManagerDelegate;
    [self reset];
    return self;
}

- (void) setSuotaFile:(SuotaFile*)suotaFile {
    _suotaFile = suotaFile;
    suotaFile.blockSize = self.blockSize;
    suotaFile.chunkSize = self.chunkSize;
    [suotaFile load];
    
    if (!suotaFile.isLoaded)
        [self notifyFailure:FIRMWARE_LOAD_FAILED];
    
    if (SuotaLibConfig.CHECK_HEADER_CRC) {
        if (suotaFile.hasHeaderInfo && !suotaFile.isHeaderCrcValid) {
            SuotaLog(TAG, @"Firmware CRC validation failed");
            [self notifyFailure:INVALID_FIRMWARE_CRC];
        }
    }
}

- (NSString*) deviceName {
    return self.peripheral != nil ? self.peripheral.name : @"";
}

- (double) avg {
    return self.suotaProtocol ? self.suotaProtocol.avg : -1;
}

- (double) max {
    return self.suotaProtocol ? self.suotaProtocol.max : -1;
}

- (double) min {
    return self.suotaProtocol ? self.suotaProtocol.min : -1;
}

- (NSDictionary<CBUUID*, NSString*>*) formattedDeviceInfoMap {
    NSMutableDictionary<CBUUID*, NSString*>* formattedDeviceInfoMap = [NSMutableDictionary dictionaryWithCapacity:self.deviceInfoMap.count];
    for(CBUUID* key in self.deviceInfoMap)
        formattedDeviceInfoMap[key] = self.deviceInfoMap[key].value.description;
    return formattedDeviceInfoMap;
}

- (NSDictionary<CBUUID*, NSString*>*) formattedSuotaInfoMap {
    NSMutableDictionary<CBUUID*, NSString*>* formattedSuotaInfoMap = [NSMutableDictionary dictionaryWithCapacity:self.suotaInfoMap.count];
    for(CBUUID* key in self.suotaInfoMap)
        formattedSuotaInfoMap[key] = self.suotaInfoMap[key].value.description;
    return formattedSuotaInfoMap;
}

- (void) readCharacteristic:(CBUUID*)uuid {
    if ([uuid isEqual:SuotaProfile.CHARACTERISTIC_MANUFACTURER_NAME_STRING]) {
        [self readManufacturer];
    } else if ([uuid isEqual:SuotaProfile.CHARACTERISTIC_MODEL_NUMBER_STRING]) {
        [self readModelNumber];
    } else if ([uuid isEqual:SuotaProfile.CHARACTERISTIC_SERIAL_NUMBER_STRING]) {
        [self readSerialNumber];
    } else if ([uuid isEqual:SuotaProfile.CHARACTERISTIC_HARDWARE_REVISION_STRING]) {
        [self readHardwareRevision];
    } else if ([uuid isEqual:SuotaProfile.CHARACTERISTIC_FIRMWARE_REVISION_STRING]) {
        [self readFirmwareRevision];
    } else if ([uuid isEqual:SuotaProfile.CHARACTERISTIC_SOFTWARE_REVISION_STRING]) {
        [self readSoftwareRevision];
    } else if ([uuid isEqual:SuotaProfile.CHARACTERISTIC_SYSTEM_ID]) {
        [self readSystemId];
    } else if ([uuid isEqual:SuotaProfile.CHARACTERISTIC_IEEE_11073]) {
        [self readIeee11073];
    } else if ([uuid isEqual:SuotaProfile.CHARACTERISTIC_PNP_ID]) {
        [self readPnpId];
    } else if ([uuid isEqual:SuotaProfile.SUOTA_VERSION_UUID]) {
        [self readSuotaVersion];
    } else if ([uuid isEqual:SuotaProfile.SUOTA_PATCH_DATA_CHAR_SIZE_UUID]) {
        [self readPatchDataSize];
    } else if ([uuid isEqual:SuotaProfile.SUOTA_MTU_UUID]) {
        [self readMtu];
    } else if ([uuid isEqual:SuotaProfile.SUOTA_L2CAP_PSM_UUID]) {
        [self readL2capPsm];
    }
}

- (GattOperation*) getReadCharacteristicCommand:(CBUUID*)uuid {
    if ([uuid isEqual:SuotaProfile.CHARACTERISTIC_MANUFACTURER_NAME_STRING]) {
        return [[GattOperation alloc] initWithCharacteristic:self.manufacturerNameCharacteristic];
    } else if ([uuid isEqual:SuotaProfile.CHARACTERISTIC_MODEL_NUMBER_STRING]) {
        return [[GattOperation alloc] initWithCharacteristic:self.modelNumberCharacteristic];
    } else if ([uuid isEqual:SuotaProfile.CHARACTERISTIC_SERIAL_NUMBER_STRING]) {
        return [[GattOperation alloc] initWithCharacteristic:self.serialNumberCharacteristic];
    } else if ([uuid isEqual:SuotaProfile.CHARACTERISTIC_HARDWARE_REVISION_STRING]) {
        return [[GattOperation alloc] initWithCharacteristic:self.hardwareRevisionCharacteristic];
    } else if ([uuid isEqual:SuotaProfile.CHARACTERISTIC_FIRMWARE_REVISION_STRING]) {
        return [[GattOperation alloc] initWithCharacteristic:self.firmwareRevisionCharacteristic];
    } else if ([uuid isEqual:SuotaProfile.CHARACTERISTIC_SOFTWARE_REVISION_STRING]) {
        return [[GattOperation alloc] initWithCharacteristic:self.softwareRevisionCharacteristic];
    } else if ([uuid isEqual:SuotaProfile.CHARACTERISTIC_SYSTEM_ID]) {
        return [[GattOperation alloc] initWithCharacteristic:self.systemIdCharacteristic];
    } else if ([uuid isEqual:SuotaProfile.CHARACTERISTIC_IEEE_11073]) {
        return [[GattOperation alloc] initWithCharacteristic:self.ieee11073Characteristic];
    } else if ([uuid isEqual:SuotaProfile.CHARACTERISTIC_PNP_ID]) {
        return [[GattOperation alloc] initWithCharacteristic:self.pnpIdCharacteristic];
    }
    return nil;
}

- (BOOL) hasDeviceInfo:(CBUUID*)uuid {
    if (self.deviceInfoService) {
        if (!uuid)
            return true;
        NSUInteger index = [self.deviceInfoService.characteristics indexOfObjectPassingTest:^BOOL (CBCharacteristic* characteristic, NSUInteger index, BOOL* stop){
            return *stop = [characteristic.UUID isEqual:uuid];
        }];
        return index != NSNotFound;
    }
    return false;
}

- (void) readManufacturer {
    [self readSpecificCharacteristic:self.manufacturerNameCharacteristic];
}

- (void) readModelNumber {
    [self readSpecificCharacteristic:self.modelNumberCharacteristic];
}

- (void) readSerialNumber {
    [self readSpecificCharacteristic:self.serialNumberCharacteristic];
}

- (void) readHardwareRevision {
    [self readSpecificCharacteristic:self.hardwareRevisionCharacteristic];
}

- (void) readFirmwareRevision {
    [self readSpecificCharacteristic:self.firmwareRevisionCharacteristic];
}

- (void) readSoftwareRevision {
    [self readSpecificCharacteristic:self.softwareRevisionCharacteristic];
}

- (void) readSystemId {
    [self readSpecificCharacteristic:self.systemIdCharacteristic];
}

- (void) readIeee11073 {
    [self readSpecificCharacteristic:self.ieee11073Characteristic];
}

- (void) readPnpId {
    [self readSpecificCharacteristic:self.pnpIdCharacteristic];
}

- (void) readSuotaVersion {
    [self readSpecificCharacteristic:self.suotaVersionCharacteristic];
}

- (void) readPatchDataSize {
    [self readSpecificCharacteristic:self.patchDataSizeCharacteristic];
}

- (void) readMtu {
    [self readSpecificCharacteristic:self.mtuCharacteristic];
}

- (void) readL2capPsm  {
    [self readSpecificCharacteristic:self.l2capPsmCharacteristic];
}

- (void) readDeviceInfo {
    if (!self.peripheral || self.state != DEVICE_CONNECTED) {
        [self notifyFailure:NOT_CONNECTED];
        return;
    }
    
    [self queueReadDeviceInfo];
}

- (void) connect {
    if (!self.peripheral) {
        SuotaLog(TAG, @"There isn't a CBPeripheral object to connect to");
        return;
    }
    if (self.state != DEVICE_DISCONNECTED) {
        SuotaLog(TAG, @"Cannot create new connection yet. The previous is still going");
        return;
    }
    if (!self.bluetoothManager.bluetoothUpdatedState) {
        pendingConnection = true;
        return;
    }
    if (self.bluetoothManager.state != CBCentralManagerStatePoweredOn) {
        SuotaLog(TAG, @"Turn Bluetooth on and try again");
        return;
    }

    [self reset];
    self.state = DEVICE_CONNECTING;
    [self.bluetoothManager connectPeripheral:self.peripheral];
}

- (void) initializeSuota {
    if ([self handleSuotaRunningOnNewConnectRequest])
        return;

    self.suotaProtocol = [[SuotaProtocol alloc] initWithManager:self];
    [self.suotaFile initBlocks:self.blockSize chunkSize:self.chunkSize];
}

- (void) initializeSuota:(int)blockSize misoGpio:(int)misoGpio mosiGpio:(int)mosiGpio csGpio:(int)csGpio sckGpio:(int)sckGpio imageBank:(int)imageBank {
    if ([self handleSuotaRunningOnNewConnectRequest])
        return;

    self.suotaProtocol = [[SuotaProtocol alloc] initWithManager:self];
    self.blockSize = blockSize;
    [self.suotaFile initBlocks:blockSize chunkSize:self.chunkSize];
    self.memoryType = MEMORY_TYPE_EXTERNAL_SPI;
    self.misoGpio = misoGpio;
    self.mosiGpio = mosiGpio;
    self.csGpio = csGpio;
    self.sckGpio = sckGpio;
    self.imageBank = imageBank;
}

- (void) initializeSuota:(int)blockSize i2cAddress:(int)i2cAddress sclGpio:(int)sclGpio sdaGpio:(int)sdaGpio imageBank:(int)imageBank {
    if ([self handleSuotaRunningOnNewConnectRequest])
        return;

    self.suotaProtocol = [[SuotaProtocol alloc] initWithManager:self];
    self.blockSize = blockSize;
    [self.suotaFile initBlocks:blockSize chunkSize:self.chunkSize];
    self.memoryType = MEMORY_TYPE_EXTERNAL_I2C;
    self.i2cDeviceAddress = i2cAddress;
    self.sclGpio = sclGpio;
    self.sdaGpio = sdaGpio;
    self.imageBank = imageBank;
}

- (void) initializeSuota:(SuotaFile*)firmware blockSize:(int)blockSize misoGpio:(int)misoGpio mosiGpio:(int)mosiGpio csGpio:(int)csGpio sckGpio:(int)sckGpio imageBank:(int)imageBank {
    [self setSuotaFile:firmware];
    [self initializeSuota:blockSize misoGpio:misoGpio mosiGpio:mosiGpio csGpio:csGpio sckGpio:sckGpio imageBank:imageBank];
}

- (void) initializeSuota:(SuotaFile*)firmware blockSize:(int)blockSize i2cAddress:(int)i2cAddress sclGpio:(int)sclGpio sdaGpio:(int)sdaGpio imageBank:(int)imageBank {
    [self setSuotaFile:firmware];
    [self initializeSuota:blockSize i2cAddress:i2cAddress sclGpio:sclGpio sdaGpio:sdaGpio imageBank:imageBank];
}

- (void) startUpdate {
    if (!self.peripheral || self.state != DEVICE_CONNECTED) {
        SuotaLog(TAG, @"Make sure to connect before trying to start update");
        [self notifyFailure:NOT_CONNECTED];
        return;
    }
    
    if (!self.suotaProtocol)
        [self initializeSuota];
    if (self.suotaProtocol.isRunning) {
        SuotaLog(TAG, @"Previous SUOTA is still running");
        return;
    }
    
    [self.suotaProtocol start];
}

- (void) disconnect {
    @synchronized (self) {
        if (!self.peripheral || self.state == DEVICE_DISCONNECTED)
            return;

        self.sendChunkOperationPending = false;
        [self.sendChunkOperationArray removeAllObjects];
        SuotaLogOpt(SuotaLibLog.MANAGER, TAG, @"Disconnecting from device");
        [self.bluetoothManager disconnectPeripheral:self.peripheral];
        if (self.suotaProtocol)
            [self.suotaProtocol destroy];
    }
}

- (void) destroy {
    @synchronized (self) {
        SuotaLog(TAG, @"Destroy");
        if (self.state != DEVICE_DISCONNECTED) {
            [self disconnect];
        }

        self.sendChunkOperationPending = false;
        [self.sendChunkOperationArray removeAllObjects];
        self.suotaProtocol = nil;
    }
}

- (int) memoryDevice {
    return (self.memoryType << 24) | self.imageBank;
}

- (int) gpioMap {
    switch (self.memoryType) {
        case MEMORY_TYPE_EXTERNAL_SPI:
            return [self spiGpioMap];
        case MEMORY_TYPE_EXTERNAL_I2C:
            return [self i2cGpioMap];
        default:
            return 0;
    }
}

- (int) spiGpioMap {
    return (self.misoGpio << 24) | (self.mosiGpio << 16) | (self.csGpio << 8) | self.sckGpio;
}

- (int) i2cGpioMap {
    return (self.i2cDeviceAddress << 16) | (self.sclGpio << 8) | self.sdaGpio;
}

- (void) close {
    SuotaLog(TAG, @"Close");
    if (self.suotaProtocol) {
        [self.suotaProtocol destroy];
        self.suotaProtocol = nil;
    }
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void) enqueueSendChunkOperation:(SendChunkOperation*)sendChunkOperation {
    @synchronized (self) {
        [self.sendChunkOperationArray addObject:sendChunkOperation];
        if (!self.sendChunkOperationPending)
            [self dequeueSendChunkOperation];
    }
}

- (void) dequeueSendChunkOperation {
    @synchronized (self) {
        self.sendChunkOperationPending = false;
        if (self.sendChunkOperationArray.count) {
            self.sendChunkOperationPending = true;
            [self executeOperation:self.sendChunkOperationArray[0]];
            [self.sendChunkOperationArray removeObjectAtIndex:0];
            if (UIDevice.currentDevice.systemVersion.floatValue < 11.0) {
                if (SuotaLibConfig.NOTIFY_CHUNK_SEND)
                    [self.suotaProtocol notifyChunkSend];
                [self dequeueSendChunkOperation];
            }
        }
    }
}

- (void) executeOperation:(GattOperation*)gattOperation {
    if (!self.peripheral || self.state != DEVICE_CONNECTED) {
        [self notifyFailure:NOT_CONNECTED];
        return;
    }

    if (gattOperation.type == REBOOT_COMMAND) {
        self.rebootSent = true;
        [self.suotaManagerDelegate onRebootSent];
    }
    [gattOperation execute:self.peripheral];
}

- (void) executeOperationArray:(NSArray<GattOperation*>*)gattOperationArray {
    for (GattOperation* operation in gattOperationArray)
        [self executeOperation:operation];
}

- (void) onSuotaProtocolSuccess {
    double elapsedTime = self.suotaProtocol ? self.suotaProtocol.elapsedTime / 1000.0 : -1;
    double uploadElapsedTime = self.suotaProtocol ? self.suotaProtocol.uploadElapsedTime / 1000.0 : -1;
    [self.suotaManagerDelegate onSuccess:elapsedTime imageUploadElapsedSeconds:uploadElapsedTime];
    
    if (SuotaLibConfig.AUTO_REBOOT) {
        [self sendRebootCommand];
    } else if (SuotaLibConfig.ALLOW_DIALOG_DISPLAY) {
        [self showRebootPromptDialog];
    }
    
    if (self.suotaProtocol)
        [self.suotaProtocol destroy];
}

- (void) onServicesDiscovered:(NSArray<CBService*>*)services {
    [self.suotaManagerDelegate onServicesDiscovered];
    NSUInteger index = [services indexOfObjectPassingTest:^BOOL (CBService* service, NSUInteger index, BOOL* stop){
        return *stop = [service.UUID isEqual:SuotaProfile.SUOTA_SERVICE_UUID];
    }];
    if (index == NSNotFound) {
        SuotaLog(TAG, @"The device does not support SUOTA");
        [self notifyFailure:SUOTA_NOT_SUPPORTED];
    } else {
        SuotaLog(TAG, @"Found SOUTA service");
        for (CBService* service in services) {
            if ([service.UUID isEqual:SuotaProfile.SUOTA_SERVICE_UUID]) {
                self.suotaService = service;
                [self.peripheral discoverCharacteristics:nil forService:service];
            } else if ([service.UUID isEqual:SuotaProfile.SERVICE_DEVICE_INFORMATION]) {
                self.deviceInfoService = service;
                [self.peripheral discoverCharacteristics:nil forService:service];
            }
        }
    }
}

- (void) onCharacteristicsDiscovered:(CBService*)service {
    if ([service.UUID isEqual:SuotaProfile.SUOTA_SERVICE_UUID]) {
        [self initSuotaCharacteristics:service];
        if ([self supportsSuotaCharacteristics]) {
            [self.peripheral discoverDescriptorsForCharacteristic:self.serviceStatusCharacteristic];
        } else {
            SuotaLog(TAG, @"The device does not support SUOTA characteristics");
            [self notifyFailure:SUOTA_NOT_SUPPORTED];
        }
    } else if ([service.UUID isEqual:SuotaProfile.SERVICE_DEVICE_INFORMATION]) {
        [self initDeviceInfoCharacteristics:service];
    }
}

- (void) onDescriptorsDiscovered:(CBCharacteristic*)characteristic {
    NSUInteger index = [characteristic.descriptors indexOfObjectPassingTest:^BOOL (CBDescriptor* desciptor, NSUInteger index, BOOL* stop){
        return *stop = [desciptor.UUID isEqual:SuotaProfile.CLIENT_CONFIG_DESCRIPTOR];
    }];
    if (index == NSNotFound) {
        SuotaLog(TAG, @"The device does not support Service Status Characteristic Configuration Client Descriptor");
        [self notifyFailure:SUOTA_NOT_SUPPORTED];
    } else {
        [self queueReadInfoOperations];
    }
}

- (void) onCharacteristicRead:(CBCharacteristic*)characteristic {
    if ([suotaInfoUuids containsObject:characteristic.UUID]) {
        [self onSuotaInfoRead:characteristic];
    } else if ([deviceInfoUuids containsObject:characteristic.UUID]) {
        [self onDeviceInfoRead:characteristic];
    } else {
        [self.suotaManagerDelegate onCharacteristicRead:OTHER characteristic:characteristic];
    }
}

- (void) onCharacteristicWrite:(CBCharacteristic*)characteristic {
    if (self.suotaProtocol)
        [self.suotaProtocol onCharacteristicWrite:characteristic];
}

- (void) onCharacteristicChanged:(CBCharacteristic*)characteristic {
    const uint8_t* value = characteristic.value.bytes;
    if (self.suotaProtocol)
        [self.suotaProtocol onCharacteristicChanged:*(uint32_t*)value];
}

- (void) onDescriptorWrite:(CBCharacteristic*)characteristic {
    if (self.suotaProtocol)
        [self.suotaProtocol onDescriptorWrite:characteristic];
}

- (void) readSpecificCharacteristic:(CBCharacteristic*)characteristic {
    if (!self.peripheral || self.state != DEVICE_CONNECTED) {
        SuotaLog(TAG, @"Make sure to connect before executing an operation");
        [self notifyFailure:NOT_CONNECTED];
        return;
    }
    if (!characteristic) {
        SuotaLog(TAG, @"Characteristic not available");
        return;
    }

    [self executeOperation:[[GattOperation alloc] initWithCharacteristic:characteristic]];
}

- (void) initSuotaCharacteristics:(CBService*)service {
    for (CBCharacteristic* characteristic in service.characteristics) {
        if ([characteristic.UUID isEqual:SuotaProfile.SUOTA_MEM_DEV_UUID])
            self.memDevCharacteristic = characteristic;
        else if ([characteristic.UUID isEqual:SuotaProfile.SUOTA_GPIO_MAP_UUID])
            self.gpioMapCharacteristic = characteristic;
        else if ([characteristic.UUID isEqual:SuotaProfile.SUOTA_MEM_INFO_UUID])
            self.memoryInfoCharacteristic = characteristic;
        else if ([characteristic.UUID isEqual:SuotaProfile.SUOTA_PATCH_LEN_UUID])
            self.patchLengthCharacteristic = characteristic;
        else if ([characteristic.UUID isEqual:SuotaProfile.SUOTA_PATCH_DATA_UUID])
            self.patchDataCharacteristic = characteristic;
        else if ([characteristic.UUID isEqual:SuotaProfile.SUOTA_SERV_STATUS_UUID])
            self.serviceStatusCharacteristic = characteristic;
        else if ([characteristic.UUID isEqual:SuotaProfile.SUOTA_VERSION_UUID])
            self.suotaVersionCharacteristic = characteristic;
        else if ([characteristic.UUID isEqual:SuotaProfile.SUOTA_PATCH_DATA_CHAR_SIZE_UUID])
            self.patchDataSizeCharacteristic = characteristic;
        else if ([characteristic.UUID isEqual:SuotaProfile.SUOTA_MTU_UUID])
            self.mtuCharacteristic = characteristic;
        else if ([characteristic.UUID isEqual:SuotaProfile.SUOTA_L2CAP_PSM_UUID])
            self.l2capPsmCharacteristic = characteristic;
    }
    
    if (self.suotaVersionCharacteristic)
        SuotaLog(TAG, @"Found SUOTA version characteristic");
    if (self.patchDataSizeCharacteristic)
        SuotaLog(TAG, @"Found SUOTA patch data char size characteristic");
    if (self.mtuCharacteristic)
        SuotaLog(TAG, @"Found SUOTA MTU characteristic");
    if (self.l2capPsmCharacteristic)
        SuotaLog(TAG, @"Found SUOTA L2CAP PSM characteristic");
}

- (void) initDeviceInfoCharacteristics:(CBService*)service {
    for (CBCharacteristic* characteristic in service.characteristics) {
        if ([characteristic.UUID isEqual:SuotaProfile.CHARACTERISTIC_MANUFACTURER_NAME_STRING])
            self.manufacturerNameCharacteristic = characteristic;
        else if ([characteristic.UUID isEqual:SuotaProfile.CHARACTERISTIC_MODEL_NUMBER_STRING])
            self.modelNumberCharacteristic = characteristic;
        else if ([characteristic.UUID isEqual:SuotaProfile.CHARACTERISTIC_SERIAL_NUMBER_STRING])
            self.serialNumberCharacteristic = characteristic;
        else if ([characteristic.UUID isEqual:SuotaProfile.CHARACTERISTIC_HARDWARE_REVISION_STRING])
            self.hardwareRevisionCharacteristic = characteristic;
        else if ([characteristic.UUID isEqual:SuotaProfile.CHARACTERISTIC_FIRMWARE_REVISION_STRING])
            self.firmwareRevisionCharacteristic = characteristic;
        else if ([characteristic.UUID isEqual:SuotaProfile.CHARACTERISTIC_SOFTWARE_REVISION_STRING])
            self.softwareRevisionCharacteristic = characteristic;
        else if ([characteristic.UUID isEqual:SuotaProfile.CHARACTERISTIC_SYSTEM_ID])
            self.systemIdCharacteristic = characteristic;
        else if ([characteristic.UUID isEqual:SuotaProfile.CHARACTERISTIC_IEEE_11073])
            self.ieee11073Characteristic = characteristic;
        else if ([characteristic.UUID isEqual:SuotaProfile.CHARACTERISTIC_PNP_ID])
            self.pnpIdCharacteristic = characteristic;
    }
}

- (void) reset {
    self.sendChunkOperationPending = false;
    [self.sendChunkOperationArray removeAllObjects];
    self.suotaInfoMap = [NSMutableDictionary dictionary];
    self.totalSuotaInfo = 0;
    self.deviceInfoMap = [NSMutableDictionary dictionary];
    self.totalDeviceInfo = 0;
    
    self.suotaService = nil;
    self.memDevCharacteristic = nil;
    self.gpioMapCharacteristic = nil;
    self.memoryInfoCharacteristic = nil;
    self.patchLengthCharacteristic = nil;
    self.patchDataCharacteristic = nil;
    self.serviceStatusCharacteristic = nil;
    self.serviceStatusClientConfigDescriptor = nil;
    self.suotaVersionCharacteristic = nil;
    self.patchDataSizeCharacteristic = nil;
    self.mtuCharacteristic = nil;
    self.l2capPsmCharacteristic = nil;

    self.deviceInfoService = nil;
    self.manufacturerNameCharacteristic = nil;
    self.modelNumberCharacteristic = nil;
    self.serialNumberCharacteristic = nil;
    self.hardwareRevisionCharacteristic = nil;
    self.firmwareRevisionCharacteristic = nil;
    self.softwareRevisionCharacteristic = nil;
    self.systemIdCharacteristic = nil;
    self.ieee11073Characteristic = nil;
    self.pnpIdCharacteristic = nil;
    
    self.suotaVersion = -1;
    self.mtu = SuotaProfile.DEFAULT_MTU;
    self.patchDataSize = SuotaLibConfig.DEFAULT_CHUNK_SIZE;
    self.chunkSize = SuotaLibConfig.DEFAULT_CHUNK_SIZE;
    self.l2capPsm = -1;
    self.suotaVersionRead = false;
    self.patchDataSizeRead = false;
    self.mtuRead = false;
    self.l2capPsmRead = false;
    
    self.manufacturerName = nil;
    self.modelNumber = nil;
    self.serialNumber = nil;
    self.hardwareRevision = nil;
    self.firmwareRevision = nil;
    self.softwareRevision = nil;
    self.systemId = nil;
    self.ieee11073 = nil;
    self.pnpId = nil;
    
    self.rebootSent = false;
    self.isDeviceInfoReadGroupPending = false;
    self.isSuotaInfoReadGroupPending = false;
}

- (BOOL) handleSuotaRunningOnNewConnectRequest {
    if (self.suotaProtocol && self.suotaProtocol.isRunning) {
        SuotaLog(TAG, @"Previous SUOTA is still running");
        return true;
    } else if (self.suotaProtocol) {
        SuotaLogOpt(SuotaLibLog.MANAGER, TAG, @"Destroying old SUOTA protocol object");
        [self.suotaProtocol destroy];
    }
    return false;
}

- (void) notifyFailure:(int)value {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.suotaManagerDelegate onFailure:value];
    });
}

- (void) onDeviceInfoRead:(CBCharacteristic*)characteristic {
    if (SuotaLibConfig.NOTIFY_DEVICE_INFO_READ)
        [self.suotaManagerDelegate onCharacteristicRead:DEVICE_INFO characteristic:characteristic];
    
    [self assignDeviceInfo:characteristic];
    
    if (!self.isDeviceInfoReadGroupPending)
        return;
    
    self.deviceInfoMap[characteristic.UUID] = characteristic;
    
    if (self.totalDeviceInfo == self.deviceInfoMap.count) {
        self.isDeviceInfoReadGroupPending = false;
        if (SuotaLibConfig.NOTIFY_DEVICE_INFO_READ_COMPLETED)
            [self.suotaManagerDelegate onDeviceInfoReadCompleted:SUCCESS];
    }
}

- (void) assignDeviceInfo:(CBCharacteristic*)characteristic {
    CBUUID* uuid = characteristic.UUID;
    if ([uuid isEqual:SuotaProfile.CHARACTERISTIC_MANUFACTURER_NAME_STRING]) {
        self.manufacturerName = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    } else if ([uuid isEqual:SuotaProfile.CHARACTERISTIC_MODEL_NUMBER_STRING]) {
        self.modelNumber = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    } else if ([uuid isEqual:SuotaProfile.CHARACTERISTIC_SERIAL_NUMBER_STRING]) {
        self.serialNumber = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    } else if ([uuid isEqual:SuotaProfile.CHARACTERISTIC_HARDWARE_REVISION_STRING]) {
        self.hardwareRevision = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    } else if ([uuid isEqual:SuotaProfile.CHARACTERISTIC_FIRMWARE_REVISION_STRING]) {
        self.firmwareRevision = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    } else if ([uuid isEqual:SuotaProfile.CHARACTERISTIC_SOFTWARE_REVISION_STRING]) {
        self.softwareRevision = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    } else if ([uuid isEqual:SuotaProfile.CHARACTERISTIC_SYSTEM_ID]) {
        self.systemId = characteristic.value;
    } else if ([uuid isEqual:SuotaProfile.CHARACTERISTIC_IEEE_11073]) {
        self.ieee11073 = characteristic.value;
    } else if ([uuid isEqual:SuotaProfile.CHARACTERISTIC_PNP_ID]) {
        self.pnpId = characteristic.value;
    }
}

- (void) onSuotaInfoRead:(CBCharacteristic*)characteristic {
    [self.suotaManagerDelegate onCharacteristicRead:SUOTA_INFO characteristic:characteristic];
    [self onSuotaReadUpdate:characteristic];

    if (!self.isSuotaInfoReadGroupPending)
        return;
    
    self.suotaInfoMap[characteristic.UUID] = characteristic;
    if (self.totalSuotaInfo == self.suotaInfoMap.count) {
        self.isSuotaInfoReadGroupPending = false;
        [self.suotaManagerDelegate onDeviceReady];
    }
}

- (void) onSuotaReadUpdate:(CBCharacteristic*)characteristic {
    const uint8_t* value = characteristic.value.bytes;
    if (!value)
        return;
    
    if ([characteristic.UUID isEqual:SuotaProfile.SUOTA_VERSION_UUID]) {
        self.suotaVersionRead = true;
        self.suotaVersion = *(uint32_t*)value;
        SuotaLog(TAG, @"SUOTA version: %d", self.suotaVersion);
    } else if ([characteristic.UUID isEqual:SuotaProfile.SUOTA_PATCH_DATA_CHAR_SIZE_UUID]) {
        self.patchDataSizeRead = true;
        self.patchDataSize = *(uint32_t*)value;
        SuotaLog(TAG, @"Patch data size: %d", self.patchDataSize);
        [self updateChunkSize];
    } else if ([characteristic.UUID isEqual:SuotaProfile.SUOTA_MTU_UUID]) {
        self.mtuRead = true;
        self.mtu = *(uint32_t*)value;
        SuotaLog(TAG, @"MTU: %d", self.mtu);
        [self updateChunkSize];
    } else if ([characteristic.UUID isEqual:SuotaProfile.SUOTA_L2CAP_PSM_UUID]) {
        self.l2capPsmRead = true;
        self.l2capPsm = *(uint32_t*)value;
        SuotaLog(TAG, @"L2CAP PSM: %d", self.l2capPsm);
    }
}

- (void) showRebootPromptDialog {
    if (!self.suotaViewController)
        return;

    UIAlertController* rebootController = [UIAlertController alertControllerWithTitle:@"Upload completed"
                                                                              message:@"Reboot device?"
                                                                       preferredStyle:UIAlertControllerStyleAlert];
    [rebootController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        [self sendRebootCommand];
    }]];
    [rebootController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        if (SuotaLibConfig.AUTO_DISCONNECT_IF_REBOOT_DENIED)
            [self disconnect];
    }]];
    [self.suotaViewController presentViewController:rebootController animated:true completion:nil];
}

- (BOOL) supportsSuotaCharacteristics {
    return (self.memDevCharacteristic
            && self.gpioMapCharacteristic
            && self.memoryInfoCharacteristic
            && self.patchLengthCharacteristic
            && self.patchDataCharacteristic
            && self.serviceStatusCharacteristic);
}

- (void) updateChunkSize {
    self.chunkSize = MIN(self.patchDataSize, self.mtu - 3);
    SuotaLogOpt(SuotaLibLog.MANAGER, TAG, @"Chunk size set to %d", self.chunkSize);
}

- (void) queueReadInfoOperations {
    if (SuotaLibConfig.AUTO_READ_DEVICE_INFO && SuotaLibConfig.READ_DEVICE_INFO_FIRST)
        [self queueReadDeviceInfo];

    [self queueReadSuotaInfo];

    if (SuotaLibConfig.AUTO_READ_DEVICE_INFO && !SuotaLibConfig.READ_DEVICE_INFO_FIRST)
        [self queueReadDeviceInfo];
}

- (NSArray<GattOperation*>*) deviceInfoReadOperations {
    NSMutableArray<GattOperation*>* gattOperations = [NSMutableArray array];
    if (SuotaLibConfig.READ_ALL_DEVICE_INFO) {
        if (self.manufacturerNameCharacteristic)
            [gattOperations addObject:[[GattOperation alloc] initWithCharacteristic:self.manufacturerNameCharacteristic]];
        if (self.modelNumberCharacteristic)
            [gattOperations addObject:[[GattOperation alloc] initWithCharacteristic:self.modelNumberCharacteristic]];
        if (self.serialNumberCharacteristic)
            [gattOperations addObject:[[GattOperation alloc] initWithCharacteristic:self.serialNumberCharacteristic]];
        if (self.hardwareRevisionCharacteristic)
            [gattOperations addObject:[[GattOperation alloc] initWithCharacteristic:self.hardwareRevisionCharacteristic]];
        if (self.firmwareRevisionCharacteristic)
            [gattOperations addObject:[[GattOperation alloc] initWithCharacteristic:self.firmwareRevisionCharacteristic]];
        if (self.softwareRevisionCharacteristic)
            [gattOperations addObject:[[GattOperation alloc] initWithCharacteristic:self.softwareRevisionCharacteristic]];
        if (self.systemIdCharacteristic)
            [gattOperations addObject:[[GattOperation alloc] initWithCharacteristic:self.systemIdCharacteristic]];
        if (self.ieee11073Characteristic)
            [gattOperations addObject:[[GattOperation alloc] initWithCharacteristic:self.ieee11073Characteristic]];
        if (self.pnpIdCharacteristic)
            [gattOperations addObject:[[GattOperation alloc] initWithCharacteristic:self.pnpIdCharacteristic]];
    } else {
        for (CBUUID* uuid in SuotaLibConfig.DEVICE_INFO_TO_READ) {
            GattOperation* operation = [self getReadCharacteristicCommand:uuid];
            if (operation)
                [gattOperations addObject:operation];
        }
    }
    return gattOperations;
}

- (void) queueReadDeviceInfo {
    if (self.state != DEVICE_CONNECTED) {
        [self notifyFailure:NOT_CONNECTED];
        return;
    }
    if (self.isDeviceInfoReadGroupPending) {
        SuotaLogOpt(SuotaLibLog.MANAGER, TAG, @"Another device info read operation is pending");
        return;
    }
    self.isDeviceInfoReadGroupPending = true;
    if (!self.deviceInfoService) {
        [self.suotaManagerDelegate onDeviceInfoReadCompleted:NO_DEVICE_INFO];
        return;
    }

    NSArray<GattOperation*>* operationsToQueue = self.deviceInfoReadOperations;

    // If no device info available to read, trigger the onInfoReadCallback now
    if (!operationsToQueue.count) {
        [self.suotaManagerDelegate onDeviceInfoReadCompleted:NO_DEVICE_INFO];
        return;
    }
    self.totalDeviceInfo += (int)operationsToQueue.count;
    [self executeOperationArray:operationsToQueue];
}

- (NSArray<GattOperation*>*) suotaInfoReadOperations {
    NSMutableArray<GattOperation*>* gattOperations = [NSMutableArray array];
    if (self.suotaVersionCharacteristic)
        [gattOperations addObject:[[GattOperation alloc] initWithCharacteristic:self.suotaVersionCharacteristic]];
    if (self.patchDataSizeCharacteristic)
        [gattOperations addObject:[[GattOperation alloc] initWithCharacteristic:self.patchDataSizeCharacteristic]];
    if (self.mtuCharacteristic)
        [gattOperations addObject:[[GattOperation alloc] initWithCharacteristic:self.mtuCharacteristic]];
    if (self.l2capPsmCharacteristic)
        [gattOperations addObject:[[GattOperation alloc] initWithCharacteristic:self.l2capPsmCharacteristic]];
    return gattOperations;
}

- (void) queueReadSuotaInfo {
    if (self.state != DEVICE_CONNECTED) {
        [self notifyFailure:NOT_CONNECTED];
        return;
    }

    self.isSuotaInfoReadGroupPending = true;
    NSArray<GattOperation*>* operationsToQueue = self.suotaInfoReadOperations;
    if (!operationsToQueue.count) {
        [self.suotaManagerDelegate onDeviceReady];
        return;
    }
    self.totalSuotaInfo += (int)operationsToQueue.count;
    [self executeOperationArray:operationsToQueue];
}

- (void) sendRebootCommand {
    if (self.state != DEVICE_CONNECTED) {
        [self notifyFailure:NOT_CONNECTED];
        return;
    }
    
    SuotaLogOpt(SuotaLibLog.MANAGER, TAG, @"Send SUOTA reboot command");
    [self executeOperation:[[GattOperation alloc] initWithType:REBOOT_COMMAND characteristic:self.memDevCharacteristic value:SUOTA_REBOOT]];
}

#pragma mark - SuotaBluetoothManager Notification selectors

- (void) onBluetoothUpdatedState:(NSNotification*)notification {
    NSNumber* state = notification.userInfo[@"state"];
    if (state.intValue == CBCentralManagerStatePoweredOn && pendingConnection) {
        pendingConnection = false;
        [self connect];
    }
}

- (void) onDeviceConnected:(NSNotification*)notification {
    CBPeripheral* peripheral = notification.userInfo[@"peripheral"];
    if (peripheral != self.peripheral)
        return;
    
    peripheral.delegate = self;
    [self.suotaManagerDelegate onConnectionStateChange:CONNECTED];
    self.state = DEVICE_CONNECTED;
    SuotaLog(TAG, @"Discover services");
    [peripheral discoverServices:nil];
}

- (void) onDeviceDisconnection:(NSNotification*)notification {
    CBPeripheral* peripheral = notification.userInfo[@"peripheral"];
    if (peripheral != self.peripheral)
        return;
    
    self.state = DEVICE_DISCONNECTED;
    [self close];
    [self.suotaManagerDelegate onConnectionStateChange:DISCONNECTED];
}

#pragma mark - PeripheralDelegate

- (void) peripheral:(CBPeripheral*)peripheral didDiscoverServices:(NSError*)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
            SuotaLog(TAG, @"Service discovery error: %@", error);
            [self notifyFailure:SERVICE_DISCOVERY_ERROR];
        } else {
            SuotaLog(TAG, @"Services discovered");
            [self onServicesDiscovered:peripheral.services];
        }
    });
}

- (void) peripheral:(CBPeripheral*)peripheral didDiscoverCharacteristicsForService:(CBService*)service error:(NSError*)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
            SuotaLog(TAG, @"Failed to read service: %@ characteristics, error: %@", service.UUID.UUIDString, error);
            [self notifyFailure:SERVICE_DISCOVERY_ERROR];
        } else {
            SuotaLogOpt(SuotaLibLog.GATT_OPERATION, TAG, @"didDiscoverCharacteristicsForService: %@ characteristics: %@", service.UUID.UUIDString, service.characteristics);
            [self onCharacteristicsDiscovered:service];
        }
    });
}

- (void) peripheral:(CBPeripheral*)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic*)characteristic error:(NSError*)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
            SuotaLog(TAG, @"Failed to read characteristic: %@ descriptors, error: %@", characteristic.UUID.UUIDString, error);
            [self notifyFailure:SERVICE_DISCOVERY_ERROR];
        } else {
            SuotaLogOpt(SuotaLibLog.GATT_OPERATION, TAG, @"didDiscoverDescriptorsForCharacteristic: %@ descriptors: %@", characteristic.UUID, characteristic.descriptors);
            [self onDescriptorsDiscovered:characteristic];
        }
    });
}

- (void) peripheral:(CBPeripheral*)peripheral didUpdateValueForCharacteristic:(CBCharacteristic*)characteristic error:(NSError*)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Considering that SUOTA_SERV_STATUS characteristic is used only for notification reception and not value reading
        if ([characteristic.UUID isEqual:SuotaProfile.SUOTA_SERV_STATUS_UUID]) {
            [self onCharacteristicChanged:characteristic];
        } else {
            if (error) {
                SuotaLog(TAG, @"Failed to read characteristic: %@ value, error: %@", characteristic.UUID, error);
                [self notifyFailure:GATT_OPERATION_ERROR];
            } else {
                SuotaLogOpt(SuotaLibLog.GATT_OPERATION, TAG, @"didUpdateValueForCharacteristic: %@ %@", characteristic.UUID, [SuotaUtils hexArray:characteristic.value]);
                [self onCharacteristicRead:characteristic];
            }
        }
    });
}

- (void) peripheralIsReadyToSendWriteWithoutResponse:(CBPeripheral*)peripheral {
    SuotaLogOpt(SuotaLibLog.GATT_OPERATION, TAG, @"peripheralIsReadyToSendWriteWithoutResponse");
    // Assuming that only the patchDataCharacteristic is used for writing without response.
    [self onCharacteristicWrite:self.patchDataCharacteristic];
    [self dequeueSendChunkOperation];
}

- (void) peripheral:(CBPeripheral*)peripheral didWriteValueForCharacteristic:(CBCharacteristic*)characteristic error:(NSError*)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (UIDevice.currentDevice.systemVersion.floatValue < 11.0 && [characteristic.UUID isEqual:SuotaProfile.SUOTA_PATCH_DATA_UUID])
            return;

        if (error) {
            SuotaLog(TAG, @"Failed to write characteristic: %@ value, error: %@", characteristic.UUID, error);
            if (!self.rebootSent)
                [self notifyFailure:GATT_OPERATION_ERROR];
        } else {
            SuotaLogOpt(SuotaLibLog.GATT_OPERATION, TAG, @"didWriteValueForCharacteristic: %@", characteristic.UUID);
            [self onCharacteristicWrite:characteristic];
        }
    });
}

- (void) peripheral:(CBPeripheral*)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic*)characteristic error:(NSError*)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
            SuotaLog(TAG, @"Failed to update notification state for characteristic: %@, error: %@", characteristic.UUID, error);
            [self notifyFailure:GATT_OPERATION_ERROR];
        } else {
            SuotaLogOpt(SuotaLibLog.GATT_OPERATION, TAG, @"didUpdateNotificationStateForCharacteristic: %@", characteristic.UUID);
            [self onDescriptorWrite:characteristic];
        }
    });
}

@end
