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

@interface SendEndSignalOperation : GattOperation

@property SuotaProtocol* suotaProtocol;

- (instancetype) initWithSuotaProtocol:(SuotaProtocol*)suotaProtocol characteristic:(CBCharacteristic*)characteristic;

@end
