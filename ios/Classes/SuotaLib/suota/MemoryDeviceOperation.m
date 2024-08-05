/*
 *******************************************************************************
 *
 * Copyright (C) 2019-2020 Dialog Semiconductor.
 * This computer program includes Confidential, Proprietary Information
 * of Dialog Semiconductor. All Rights Reserved.
 *
 *******************************************************************************
 */

#import "MemoryDeviceOperation.h"
#import "SuotaProtocol.h"

@implementation MemoryDeviceOperation

- (instancetype) initWithProtocol:(SuotaProtocol*)suotaProtocol characteristic:(CBCharacteristic*)characteristic value:(int)value {
    self = [super initWithType:WRITE characteristic:characteristic value:value];
    if (!self)
        return nil;
    self.suotaProtocol = suotaProtocol;
    return self;
}

- (void) execute:(CBPeripheral*)peripheral {
    [self.suotaProtocol notifyForSendingMemoryDevice];
    [self executeWriteCharacteristic:peripheral];
}

@end
