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
#import <CoreBluetooth/CoreBluetooth.h>

@class SuotaManager;

@protocol BluetoothManagerScannerDelegate <NSObject>

@required

- (void) didDiscoverPeripheral:(CBPeripheral*)peripheral advertisementData:(NSDictionary<NSString*,id>*)advertisementData RSSI:(NSNumber*)RSSI;

@end

extern NSString* const SuotaBluetoothManagerUpdatedState;
extern NSString* const SuotaBluetoothManagerConnectionFailed;
extern NSString* const SuotaBluetoothManagerDeviceConnected;
extern NSString* const SuotaBluetoothManagerDeviceDisconnected;

@interface SuotaBluetoothManager : NSObject <CBCentralManagerDelegate>

@property CBCentralManager* bluetoothManager;
@property dispatch_queue_t bleQueue;
@property (weak) id<BluetoothManagerScannerDelegate> scannerDelegate;
@property enum CBCentralManagerState state;
@property BOOL bluetoothUpdatedState;

+ (SuotaBluetoothManager*) instance;

- (CBPeripheral*) retrievePeripheralWithIdentifier:(NSUUID*)identifier;
- (void) scan;
- (void) stopScan;
- (void) connectPeripheral:(CBPeripheral*)peripheral;
- (void) disconnectPeripheral:(CBPeripheral*)peripheral;

@end
