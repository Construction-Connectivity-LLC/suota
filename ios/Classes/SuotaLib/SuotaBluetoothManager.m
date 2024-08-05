/*
 *******************************************************************************
 *
 * Copyright (C) 2019-2020 Dialog Semiconductor.
 * This computer program includes Confidential, Proprietary Information
 * of Dialog Semiconductor. All Rights Reserved.
 *
 *******************************************************************************
 */

#import "SuotaBluetoothManager.h"
#import "SuotaLibLog.h"
#import "SuotaManager.h"
#import "SuotaUtils.h"

@implementation SuotaBluetoothManager

static SuotaBluetoothManager *instance;
static NSString* const TAG = @"SuotaBluetoothManager";

NSString* const SuotaBluetoothManagerUpdatedState = @"SuotaBluetoothManagerUpdatedState";
NSString* const SuotaBluetoothManagerConnectionFailed = @"SuotaBluetoothManagerConnectionFailed";
NSString* const SuotaBluetoothManagerDeviceConnected = @"SuotaBluetoothManagerDeviceConnected";
NSString* const SuotaBluetoothManagerDeviceDisconnected = @"SuotaBluetoothManagerDeviceDisconnected";


+ (SuotaBluetoothManager*) instance {
    @synchronized (self) {
        if (!instance)
            instance = [SuotaBluetoothManager new];
    }
    return instance;
}

- (instancetype) init {
    self = [super init];
    if (!self)
        return nil;
    self.bleQueue = dispatch_queue_create("SuotaBluetoothManager", DISPATCH_QUEUE_SERIAL);
    self.bluetoothManager = [[CBCentralManager alloc] initWithDelegate:self queue:self.bleQueue];
    return self;
}

- (CBPeripheral*) retrievePeripheralWithIdentifier:(NSUUID*)identifier {
    NSArray<CBPeripheral*>* knownDevices = [self.bluetoothManager retrievePeripheralsWithIdentifiers:@[identifier]];
    if (!knownDevices.count) {
        SuotaLog(TAG, @"Can't retrieve peripheral with identifier: %@", identifier.UUIDString);
        return nil;
    }
    return knownDevices[0];
}

- (void) scan {
    if (self.state == CBCentralManagerStatePoweredOn)
        [self.bluetoothManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @(true)}];
}

- (void) stopScan {
    if (self.state == CBCentralManagerStatePoweredOn)
        [self.bluetoothManager stopScan];
}

- (void) connectPeripheral:(CBPeripheral*)peripheral {
    if (self.state == CBCentralManagerStatePoweredOn)
        [self.bluetoothManager connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey: @(true)}];
}

- (void) disconnectPeripheral:(CBPeripheral*)peripheral {
    if (self.state == CBCentralManagerStatePoweredOn)
        [self.bluetoothManager cancelPeripheralConnection:peripheral];
}

#pragma mark - CBCentralManagerDelegate

- (void) centralManagerDidUpdateState:(nonnull CBCentralManager *)central {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.state = (CBCentralManagerState)central.state;
        switch (central.state) {
            case CBCentralManagerStatePoweredOff:
                SuotaLog(TAG, @"CoreBluetooth BLE hardware is powered off");
                break;
            case CBCentralManagerStatePoweredOn:
                SuotaLog(TAG, @"CoreBluetooth BLE hardware is powered on and ready");
                break;
            case CBCentralManagerStateResetting:
                SuotaLog(TAG, @"CoreBluetooth BLE hardware is resetting");
                break;
            case CBCentralManagerStateUnauthorized:
                SuotaLog(TAG, @"CoreBluetooth BLE state is unauthorized");
                break;
            case CBCentralManagerStateUnknown:
                SuotaLog(TAG, @"CoreBluetooth BLE state is unknown");
                break;
            case CBCentralManagerStateUnsupported:
                SuotaLog(TAG, @"CoreBluetooth BLE hardware is unsupported on this platform");
                break;
            default:
                SuotaLog(TAG, @"Unknown state");
                break;
        }
        if (!self.bluetoothUpdatedState)
            self.bluetoothUpdatedState = true;
        NSDictionary* info = @{@"state" : @(central.state)};
        [NSNotificationCenter.defaultCenter postNotificationName:SuotaBluetoothManagerUpdatedState object:self userInfo:info];
    });
}

- (void) centralManager:(CBCentralManager*)central didDiscoverPeripheral:(CBPeripheral*)peripheral advertisementData:(NSDictionary<NSString*,id>*)advertisementData RSSI:(NSNumber*)RSSI {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.scannerDelegate && [self.scannerDelegate respondsToSelector:@selector(didDiscoverPeripheral:advertisementData:RSSI:)]) {
            [self.scannerDelegate didDiscoverPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
        }
    });
}

- (void) centralManager:(CBCentralManager*)central didConnectPeripheral:(CBPeripheral*)peripheral {
    dispatch_async(dispatch_get_main_queue(), ^{
        SuotaLog(TAG, @"Device connected: %@", peripheral.name);
        NSDictionary* info = @{@"peripheral" : peripheral};
        [NSNotificationCenter.defaultCenter postNotificationName:SuotaBluetoothManagerDeviceConnected object:self userInfo:info];
    });
}

- (void) centralManager:(CBCentralManager*)central didFailToConnectPeripheral:(CBPeripheral*)peripheral error:(NSError*)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        SuotaLog(TAG, @"Device connection error: %@ %@", peripheral.name, error);
        NSDictionary* info = @{@"peripheral" : peripheral, @"error" : error};
        [NSNotificationCenter.defaultCenter postNotificationName:SuotaBluetoothManagerConnectionFailed object:self userInfo:info];
    });
}

- (void) centralManager:(CBCentralManager*)central didDisconnectPeripheral:(CBPeripheral*)peripheral error:(NSError*)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error)
            SuotaLog(TAG, @"Device disconnected: %@, error: %@", peripheral.name, error);
        else
            SuotaLog(TAG, @"Device disconnected: %@", peripheral.name);
        NSDictionary* info = !error ? @{@"peripheral" : peripheral} : @{@"peripheral" : peripheral, @"error" : error};
        [NSNotificationCenter.defaultCenter postNotificationName:SuotaBluetoothManagerDeviceDisconnected object:self userInfo:info];
    });
}

@end
