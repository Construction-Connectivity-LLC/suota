/*
 *******************************************************************************
 *
 * Copyright (C) 2019 Dialog Semiconductor.
 * This computer program includes Confidential, Proprietary Information
 * of Dialog Semiconductor. All Rights Reserved.
 *
 *******************************************************************************
 */

#import "GattOperation.h"

@class SuotaProtocol;

@interface MemoryDeviceOperation : GattOperation

@property SuotaProtocol* suotaProtocol;

- (instancetype) initWithProtocol:(SuotaProtocol*)suotaProtocol characteristic:(CBCharacteristic*)characteristic value:(int)value;

@end
