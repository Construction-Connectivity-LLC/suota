/*
 *******************************************************************************
 *
 * Copyright (C) 2019-2020 Dialog Semiconductor.
 * This computer program includes Confidential, Proprietary Information
 * of Dialog Semiconductor. All Rights Reserved.
 *
 *******************************************************************************
 */

#import "GattOperation.h"
#import "SuotaLibLog.h"
#import "SuotaUtils.h"

@implementation GattOperation

static NSString* const TAG = @"GattOperation";

- (instancetype) initWithCharacteristic:(CBCharacteristic*)characteristic {
    self = [super init];
    if (!self)
        return nil;
    self.type = READ;
    self.characteristic = characteristic;
    return self;
}

- (instancetype) initWithType:(enum OperationType)type characteristic:(CBCharacteristic*)characteristic valueData:(NSData*)valueData {
    self = [super init];
    if (!self)
        return nil;
    self.type = type;
    self.characteristic = characteristic;
    self.value = valueData;
    return self;
}

- (instancetype) initWithType:(enum OperationType)type characteristic:(CBCharacteristic*)characteristic value:(int)value {
    return [self initWithType:type characteristic:characteristic valueData:[NSData dataWithBytes:&value length:sizeof(value)]];
}

- (instancetype) initWithCharacteristic:(CBCharacteristic*)characteristic value:(uint16_t)value {
    return [self initWithCharacteristic:characteristic valueData:[NSData dataWithBytes:&value length:sizeof(value)]];
}

- (instancetype) initWithCharacteristic:(CBCharacteristic*)characteristic valueData:(NSData*)valueData {
    self = [super init];
    if (!self)
        return nil;
    self.type = WRITE;
    self.characteristic = characteristic;
    self.value = valueData;
    return self;
}

- (instancetype) initWithDescriptor:(CBDescriptor*)descriptor valueData:(NSData*)valueData {
    self = [super init];
    if (!self)
        return nil;
    self.type = WRITE_DESCRIPTOR;
    self.descriptor = descriptor;
    self.value = valueData;
    return self;
}

- (instancetype) initWithDescriptorForNotificationStatus:(CBCharacteristic*)characteristic notificationStatus:(BOOL)status {
    self = [super init];
    if (!self)
        return nil;
    self.type = SET_NOTIFICATION_STATUS;
    self.characteristic = characteristic;
    self.notificationStatus = status;
    return self;
}

- (void) execute:(CBPeripheral*)peripheral {
    if (self.type == WRITE || self.type == WRITE_WITHOUT_RESPONSE || self.type == REBOOT_COMMAND) {
        [self executeWriteCharacteristic:peripheral];
    } else if (self.type == READ) {
        [self executeReadCharacteristic:peripheral];
    } else if (self.type == WRITE_DESCRIPTOR) {
        [self executeWriteDescriptor:peripheral];
    } else if (self.type == SET_NOTIFICATION_STATUS) {
        [self executeChangeNotificationStatus:peripheral];
    }
}

- (void) executeWriteCharacteristic:(CBPeripheral*)peripheral {
    SuotaLogOpt(SuotaLibLog.GATT_OPERATION, TAG, @"Write characteristic: %@ %@", self.characteristic.UUID.UUIDString, [SuotaUtils hexArray:self.value]);
    [peripheral writeValue:self.value forCharacteristic:self.characteristic type:self.type == WRITE_WITHOUT_RESPONSE ? CBCharacteristicWriteWithoutResponse : CBCharacteristicWriteWithResponse];
}

- (void) executeReadCharacteristic:(CBPeripheral*)peripheral {
    SuotaLogOpt(SuotaLibLog.GATT_OPERATION, TAG, @"Read characteristic: %@", self.characteristic.UUID.UUIDString);
    [peripheral readValueForCharacteristic:self.characteristic];
}

- (void) executeWriteDescriptor:(CBPeripheral*)peripheral {
    SuotaLogOpt(SuotaLibLog.GATT_OPERATION, TAG, @"Write descriptor: %@ %@ %@", self.descriptor.characteristic.UUID.UUIDString, self.descriptor.UUID.UUIDString, [SuotaUtils hexArray:self.value]);
    [peripheral writeValue:self.value forDescriptor:self.descriptor];
}

- (void) executeChangeNotificationStatus:(CBPeripheral*)peripheral {
    SuotaLogOpt(SuotaLibLog.GATT_OPERATION, TAG, @"Change notification status: %@ %@", self.notificationStatus ? @"true" : @"false", self.characteristic.UUID.UUIDString);
    [peripheral setNotifyValue:self.notificationStatus forCharacteristic:self.characteristic];
}

@end
