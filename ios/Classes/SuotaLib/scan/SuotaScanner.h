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
 @header SuotaScanner.h
 @brief Header file for the SuotaScanner class.
 
 This header file contains method and property declaration for the SuotaScanner and ScannerBuilder classes. It also contains the declaration for SuotaScannerDelegate protocol.
 
 @copyright 2019 Dialog Semiconductor
 */

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <UIKit/UIKit.h>
#import "SuotaBluetoothManager.h"
#import "SuotaProfile.h"

/*!
 *  @protocol SuotaScannerDelegate
 *
 *  @discussion The {@link scanDelegate} must adopt the <code>SuotaScannerDelegate</code> protocol. The methods allow for information on the scanning process.
 *
 */
@protocol SuotaScannerDelegate <NSObject>

@required

/*!
 * @method onFailure:
 *
 * @param failure Reason that caused the failure.
 *
 * @discussion Triggered every time that a scan fails.
 *
 */
- (void) onFailure:(enum ScanFailure)failure;

@required

/*!
 * @method onDeviceScan:rssi:scanRecord:
 *
 * @param peripheral The BLE device found.
 * @param rssi The rssi.
 * @param scanRecord The scan record that the device advertises.
 *
 * @discussion Triggered every time that a new BLE device is found through scanning.
 */
- (void) onDeviceScan:(CBPeripheral*)peripheral rssi:(NSNumber*)rssi scanRecord:(NSDictionary*)scanRecord;

@required

/*!
 * @method onScanStatusChange:
 *
 * @param newStatus The new scan status.
 *
 * @discussion Triggered every time the scan status changes.
 */
- (void) onScanStatusChange:(enum ScanStatus)newStatus;

@end


/*!
 * @class ScannerBuilder
 *
 * @brief Builder pattern is used in order to create a SuotaScanner object. User can override some of the library configuration.
 *
 * @discussion Builder usage example:
 *
 * <tt> @textblock
 SuotaScanner* scanner = [SuotaScanner scannerWithBuilderBlock:^(ScannerBuilder* builder){
     builder.allowDialogDisplay = true;
     builder.viewController = self;
     builder.scanTimeout = 20000;
 }];
 @/textblock </tt>
 *
 */
@interface ScannerBuilder : NSObject

/*!
 * @property viewController
 *
 * @discussion {@link UIViewController} object used to show user dialogs. A {@link UIViewController} object must be set if the {@link allowDialogDisplay} property value is
 * <code>true</code>.
 */
@property UIViewController* viewController;

/*!
 * @property allowDialogDisplay
 *
 * @discussion Indicates if the app is permitted to create user dialogs. Overrides the {@link ALLOW_DIALOG_DISPLAY} default value just for this SuotaScanner object.
 *
 */
@property BOOL allowDialogDisplay;

/*!
 * @property scanTimeout
 *
 * @discussion Scan timeout value. Overrides the {@link DEFAULT_SCAN_TIMEOUT} default value just for this SuotaScanner object.
 */
@property long scanTimeout;

- (id) build;

@end


/*!
 * @class SuotaScanner
 *
 * @discussion Scanner used to scan for BLE devices.
 *
 */
@interface SuotaScanner : NSObject <BluetoothManagerScannerDelegate>

/*!
 *  @property scanDelegate
 *
 *  @discussion The delegate object that will receive {@link SuotaScanner} events.
 *
 */
@property (weak) id<SuotaScannerDelegate> scanDelegate;
@property SuotaBluetoothManager* bluetoothManager;
@property (weak) UIViewController* viewController;

/*!
 * @property isScanning
 *
 * @discussion Indicates if there is a scan currently running.
 *
 */
@property BOOL isScanning;
@property BOOL onlySUOTAUuidSearch;
@property BOOL allowDialogDisplay;

/*!
 * @property scanTimeout
 *
 * @discussion Scan timeout value.
 *
 */
@property long scanTimeout;

@property NSArray<CBUUID*>* uuids;

/*!
 * @method scannerWithBuilderBlock:
 *
 * @param block {@link ScannerBuilder} property value initialization block.
 *
 * @discussion Creates a {@link SuotaScanner} object using the builder pattern. Returns nil if the {@link allowDialogDisplay} value is set to true but there is not any view controller provided.
 *
 * Builder usage example:
 *
 * <tt> @textblock
 SuotaScanner* scanner = [SuotaScanner scannerWithBuilderBlock:^(ScannerBuilder* builder){
 builder.allowDialogDisplay = true;
 builder.viewController = self;
 builder.scanTimeout = 20000;
 }];
 @/textblock </tt>
 *
 * @return {@link SuotaScanner} object.
 *
 */
+ (instancetype) scannerWithBuilderBlock:(void(^)(ScannerBuilder*))block;

- (id) initWithBuilder:(ScannerBuilder*)builder;

/*!
 * @method scan:
 *
 * @param scanDelegate Receives scan status updates.
 *
 * @discussion Scans for devices advertising the <code>SUOTA_SERVICE_UUID</code>. Uses the {@link //apple_ref/occ/instp/SuotaScanner/scanTimeout} value.
 *
 */
- (void) scan:(id<SuotaScannerDelegate>)scanDelegate;

/*!
 * @method scan:scanTimeout
 *
 * @param scanDelegate Receives scan status updates.
 * @param scanTimeout Scan timeout value.
 *
 * @discussion Scans for devices advertising the <code>SUOTA_SERVICE_UUID</code>.
 *
 * @see scan:
 */
- (void) scan:(id<SuotaScannerDelegate>)scanDelegate scanTimeout:(long)scanTimeout;

/*!
 * @method scan:uuids
 *
 * @param scanDelegate Receives scan status updates.
 * @param uuids UUID values to search for in advertising data.
 *
 * @discussion Scans for devices advertising any of the given UUID values. Uses the {@link //apple_ref/occ/instp/SuotaScanner/scanTimeout} value.
 *
 * @see scan:
 */
- (void) scan:(id<SuotaScannerDelegate>)scanDelegate uuids:(NSArray<CBUUID*>*)uuids;

/*!
 * @method scan:uuids:scanTimeout
 *
 * @param scanDelegate Receives scan status updates.
 * @param uuids UUID values to search for in advertising data.
 * @param scanTimeout Scan timeout value.
 *
 * @discussion Scans for devices advertising any of the given UUID values.
 *
 * @see scan:
 */
- (void) scan:(id<SuotaScannerDelegate>)scanDelegate uuids:(NSArray<CBUUID*>*)uuids scanTimeout:(long)scanTimeout;

/*!
 * @method stopScan
 *
 * @discussion Stops scanning if there is an active scanning process.
 *
 */
- (void) stopScan;

/*!
 * @method destroy
 *
 * @discussion Stops scan if running, sets the delegate to nil, dismisses any dialog if visible.
 *
 */
- (void) destroy;

@end
