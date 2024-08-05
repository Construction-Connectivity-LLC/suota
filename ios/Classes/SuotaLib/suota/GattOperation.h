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

@interface GattOperation : NSObject

enum OperationType {
    READ,
    WRITE,
    WRITE_WITHOUT_RESPONSE,
    WRITE_DESCRIPTOR,
    SET_NOTIFICATION_STATUS,
    REBOOT_COMMAND
};

@property CBCharacteristic* characteristic;
@property CBDescriptor* descriptor;
@property enum OperationType const type;
@property NSData* value;
@property BOOL notificationStatus;

- (instancetype) initWithCharacteristic:(CBCharacteristic*)characteristic;
- (instancetype) initWithType:(enum OperationType)type characteristic:(CBCharacteristic*)characteristic valueData:(NSData*)value;
- (instancetype) initWithType:(enum OperationType)type characteristic:(CBCharacteristic*)characteristic value:(int)value;
- (instancetype) initWithCharacteristic:(CBCharacteristic*)characteristic value:(uint16_t)value;
- (instancetype) initWithCharacteristic:(CBCharacteristic*)characteristic valueData:(NSData*)valueData;
- (instancetype) initWithDescriptor:(CBDescriptor*)descriptor valueData:(NSData*)valueData;
- (instancetype) initWithDescriptorForNotificationStatus:(CBCharacteristic*)characteristic notificationStatus:(BOOL)status;

- (void) execute:(CBPeripheral*)peripheral;
- (void) executeWriteCharacteristic:(CBPeripheral*)peripheral;

@end
