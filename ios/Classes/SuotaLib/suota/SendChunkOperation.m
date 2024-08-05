/*
 *******************************************************************************
 *
 * Copyright (C) 2019-2020 Dialog Semiconductor.
 * This computer program includes Confidential, Proprietary Information
 * of Dialog Semiconductor. All Rights Reserved.
 *
 *******************************************************************************
 */

#import "SendChunkOperation.h"
#import "SuotaLibConfig.h"
#import "SuotaProtocol.h"

@implementation SendChunkOperation

- (instancetype) initWithSuotaProtocol:(SuotaProtocol*)suotaProtocol characteristic:(CBCharacteristic*)characteristic valueData:(NSData*)valueData chunkCount:(int)chunkCount chunk:(int)chunk block:(int)block isLastChunk:(BOOL)isLastChunk {
    self = [super initWithType:WRITE_WITHOUT_RESPONSE characteristic:characteristic valueData:valueData];
    if (!self)
        return nil;
    self.suotaProtocol = suotaProtocol;
    self.chunkCount = chunkCount;
    self.chunk = chunk;
    self.block = block;
    self.isLastChunk = isLastChunk;
    return self;
}

- (void) execute:(CBPeripheral*)peripheral {
    [self.suotaProtocol notifyForSendingChunk:self];
    if (SuotaLibConfig.CALCULATE_STATISTICS)
        self.sendStartTime = [[NSDate date] timeIntervalSince1970] * 1000;
    [self executeWriteCharacteristic:peripheral];
}

@end
