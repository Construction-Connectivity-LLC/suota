/*
 *******************************************************************************
 *
 * Copyright (C) 2019-2020 Dialog Semiconductor.
 * This computer program includes Confidential, Proprietary Information
 * of Dialog Semiconductor. All Rights Reserved.
 *
 *******************************************************************************
 */

#import "SendEndSignalOperation.h"
#import "SuotaManager.h"
#import "SuotaProtocol.h"

@implementation SendEndSignalOperation

- (instancetype) initWithSuotaProtocol:(SuotaProtocol*)suotaProtocol characteristic:(CBCharacteristic*)characteristic {
    self = [super initWithType:WRITE characteristic:characteristic value:SUOTA_END];
    if (!self)
        return nil;
    self.suotaProtocol = suotaProtocol;
    return self;
}

- (void) execute:(CBPeripheral*)peripheral {
    [self.suotaProtocol notifyForSendingEndSignal];
    [self executeWriteCharacteristic:peripheral];
}

@end
