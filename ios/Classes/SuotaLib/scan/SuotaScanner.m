/*
 *******************************************************************************
 *
 * Copyright (C) 2019-2020 Dialog Semiconductor.
 * This computer program includes Confidential, Proprietary Information
 * of Dialog Semiconductor. All Rights Reserved.
 *
 *******************************************************************************
 */

#import "SuotaScanner.h"
#import "SuotaBluetoothManager.h"
#import "SuotaLibConfig.h"
#import "SuotaLibLog.h"

@implementation ScannerBuilder

static NSString* const SCANNER_TAG = @"ScannerBuilder";

- (instancetype) init {
    self = [super init];
    if (!self)
        return nil;
    self.allowDialogDisplay = SuotaLibConfig.ALLOW_DIALOG_DISPLAY;
    self.scanTimeout = SuotaLibConfig.DEFAULT_SCAN_TIMEOUT;
    return self;
}

- (SuotaScanner*) build {
    if (self.allowDialogDisplay && !self.viewController) {
        SuotaLogOpt(SuotaLibLog.SCAN_ERROR, SCANNER_TAG, @"Cannot create SuotaScanner without providing a view controller when ALLOW_DIALOG_DISPLAY is enabled.");
        return nil;
    }
    return [[SuotaScanner alloc] initWithBuilder:self];
}

@end

@implementation SuotaScanner {
    BOOL pendingScan;
}

static NSString* const TAG = @"SuotaScanner";

+ (instancetype) scannerWithBuilderBlock:(void(^)(ScannerBuilder*))block {
    NSParameterAssert(block);
    
    ScannerBuilder* builder = [[ScannerBuilder alloc] init];
    block(builder);
    return [builder build];
}

- (instancetype) initWithBuilder:(ScannerBuilder*)builder {
    self = [super init];
    if (!self)
        return nil;
    self.scanTimeout = builder.scanTimeout;
    self.allowDialogDisplay = builder.allowDialogDisplay;
    self.viewController = builder.viewController;
    self.onlySUOTAUuidSearch = true;
    self.bluetoothManager = [SuotaBluetoothManager instance];
    self.bluetoothManager.scannerDelegate = self;
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onBluetoothUpdatedState:) name:SuotaBluetoothManagerUpdatedState object:self.bluetoothManager];
    return self;
}

- (void) scan:(id<SuotaScannerDelegate>)scanDelegate {
    self.scanDelegate = scanDelegate;
    [self scanDevices];
}

- (void) scan:(id<SuotaScannerDelegate>)scanDelegate scanTimeout:(long)scanTimeout {
    self.scanTimeout = scanTimeout;
    [self scan:scanDelegate];
}

- (void) scan:(id<SuotaScannerDelegate>)scanDelegate uuids:(NSArray<CBUUID*>*)uuids {
    self.onlySUOTAUuidSearch = false;
    self.uuids = uuids;
    [self scan:scanDelegate];
}

- (void) scan:(id<SuotaScannerDelegate>)scanDelegate uuids:(NSArray<CBUUID*>*)uuids scanTimeout:(long)scanTimeout {
    self.scanTimeout = scanTimeout;
    [self scan:scanDelegate uuids:uuids];
}

- (void) stopScan {
    SuotaLogOpt(SuotaLibLog.SCAN_DEBUG, TAG, @"Stop scanning");
    if (!self.isScanning)
        return;
    self.isScanning = false;
    [self triggerOnScanStatusChanged:STOPPED];
    [self.bluetoothManager stopScan];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopScan) object:nil];
    // resets
    self.onlySUOTAUuidSearch = true;
    self.uuids = nil;
}

- (void) destroy {
    SuotaLog(TAG, @"Destroy scanner");
    [self stopScan];
    self.scanDelegate = nil;
    self.viewController = nil;
}

- (BOOL) checkRequirements {
    if (self.bluetoothManager.state == CBCentralManagerStateUnsupported) {
        SuotaLogOpt(SuotaLibLog.SCAN_DEBUG, TAG, @"Bluetooth not supported");
        [self triggerOnFailure:BLE_NOT_SUPPORTED];
        return false;
    } else if (self.bluetoothManager.state != CBCentralManagerStatePoweredOn) {
        SuotaLogOpt(SuotaLibLog.SCAN_DEBUG, TAG, @"Bluetooth adapter is off");
        [self handleBluetoothNotEnabled];
        return false;
    }
    return true;
}

- (void) handleBluetoothNotEnabled {
    [self triggerOnFailure:BLUETOOTH_NOT_ENABLED];
}

- (void) scanDevices {
    if (!self.bluetoothManager.bluetoothUpdatedState) {
        pendingScan = true;
        return;
    }
    if (![self checkRequirements])
        return;
    if (self.isScanning)
        [self stopScan];
    SuotaLogOpt(SuotaLibLog.SCAN_DEBUG, TAG, @"Start Scanning");
    self.isScanning = true;
    [self performSelector:@selector(stopScan) withObject:nil afterDelay:self.scanTimeout / 1000.0];
    [self triggerOnScanStatusChanged:STARTED];
    [self.bluetoothManager scan];
}

- (void) triggerOnScanStatusChanged:(enum ScanStatus)status {
    if (self.scanDelegate)
        [self.scanDelegate onScanStatusChange:status];
}

- (void) triggerOnDeviceScan:(CBPeripheral*)peripheral rssi:(NSNumber*)rssi scanRecord:(NSDictionary*)scanRecord {
    if (self.scanDelegate)
        [self.scanDelegate onDeviceScan:peripheral rssi:rssi scanRecord:scanRecord];
}

- (void) triggerOnFailure:(enum ScanFailure)failure {
    if (self.scanDelegate)
        [self.scanDelegate onFailure:failure];
}

#pragma mark - SuotaBluetoothManager SuotaBluetoothManagerUpdatedState Notification selector

- (void) onBluetoothUpdatedState:(NSNotification*)notification {
    NSNumber* state = notification.userInfo[@"state"];
    switch (state.intValue) {
        case CBCentralManagerStatePoweredOn:
            if (pendingScan) {
                pendingScan = false;
                [self scanDevices];
            }
            break;
            
        case CBCentralManagerStatePoweredOff:
            if (self.isScanning)
                [self stopScan];
            break;
            
        default:
            break;
    }
}

#pragma mark - BluetoothManagerScannerDelegate

- (void) didDiscoverPeripheral:(CBPeripheral*)peripheral advertisementData:(NSDictionary<NSString*,id>*)advertisementData RSSI:(NSNumber *)RSSI {
    SuotaLogOpt(SuotaLibLog.SCAN_DEBUG, TAG, @"Discovered item %@ (advertisement: %@)", peripheral, advertisementData);
    NSArray *services = [advertisementData valueForKey:CBAdvertisementDataServiceUUIDsKey];
    NSArray *servicesOvfl = [advertisementData valueForKey:CBAdvertisementDataOverflowServiceUUIDsKey];
    if (!self.onlySUOTAUuidSearch) {
        if (!self.uuids || self.uuids.count == 0) {
            [self triggerOnDeviceScan:peripheral rssi:RSSI scanRecord:advertisementData];
        } else {
            for (CBUUID* uuid in self.uuids) {
                if ([services containsObject:uuid] || [servicesOvfl containsObject:uuid]) {
                    [self triggerOnDeviceScan:peripheral rssi:RSSI scanRecord:advertisementData];
                    break;
                }
            }
        }
    } else {
        if ([services containsObject:SuotaProfile.SUOTA_SERVICE_UUID] || [servicesOvfl containsObject:SuotaProfile.SUOTA_SERVICE_UUID]) {
           [self triggerOnDeviceScan:peripheral rssi:RSSI scanRecord:advertisementData];
        }
    }
}

@end
