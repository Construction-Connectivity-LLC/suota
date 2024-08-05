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
 @header SuotaProtocol.h
 @brief Header file for the SuotaProtocol and the SpeedStatistics classes.
 
 This header file contains method and property declaration for the SuotaProtocol and the SpeedStatistics classes.
 
 @copyright 2019 Dialog Semiconductor
 */

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "SuotaManager.h"
#import "SuotaProfile.h"

@class SendChunkOperation;

/*!
 * @class SpeedStatistics
 *
 * @discussion This class generates speed statistics for the protocol image upload procedure.
 *
 */
@interface SpeedStatistics : NSObject

@property uint64_t uploadStartTime;
@property int bytesSent;
@property double uploadAvg;
@property NSMutableArray<NSNumber*>* speeds;
@property double sum;
@property double max;
@property double min;

- (void) update:(int)size speed:(double)speed;
- (double) avg;

@end


/*!
 * @class SuotaProtocol
 *
 * @discussion This class defines the protocol used for the SUOTA process.
 *
 */
@interface SuotaProtocol : NSObject

@property (weak) SuotaManager* suotaManager;
@property (weak) id<SuotaManagerDelegate> suotaManagerDelegate;
@property SuotaFile* suotaFile;
@property enum SuotaProtocolState state;
@property NSTimer* timeoutTimer;

@property uint64_t startTime;
@property uint64_t elapsedTime;
@property uint64_t uploadStartTime;
@property uint64_t uploadElapsedTime;
@property uint64_t currentBlockStartTime;

@property BOOL suotaRunning;
@property BOOL memoryDeviceSent;
@property BOOL endSignalSent;

@property int currentBlock;
@property SendChunkOperation* lastChunk;

@property SpeedStatistics* statistics;
@property NSTimer* currentSpeedTimer;

@property int bytesSent;

- (instancetype) initWithManager:(SuotaManager*)suotaManager;

- (void) start;
- (BOOL) isRunning;
- (void) notifyForSendingChunk:(SendChunkOperation*)sendChunkOperation;
- (void) notifyForSendingMemoryDevice;
- (void) notifyForSendingEndSignal;
- (void) destroy;
- (double) uploadAvg;
- (double) avg;
- (double) max;
- (double) min;
- (void) onCharacteristicChanged:(int)value;
- (void) onCharacteristicWrite:(CBCharacteristic*)characteristic;
- (void) onDescriptorWrite:(CBCharacteristic*)characteristic;
- (void) notifyChunkSend;

@end
