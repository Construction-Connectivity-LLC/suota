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

@class SuotaProtocol;

@interface SendChunkOperation : GattOperation

@property (weak) SuotaProtocol* suotaProtocol;

@property int chunkCount;
@property int chunk;
@property int block;
@property BOOL isLastChunk;
@property uint64_t sendStartTime;

- (instancetype) initWithSuotaProtocol:(SuotaProtocol*)suotaProtocol characteristic:(CBCharacteristic*)characteristic valueData:(NSData*)valueData chunkCount:(int)chunkCount chunk:(int)chunk block:(int)block isLastChunk:(BOOL)isLastChunk;

@end
