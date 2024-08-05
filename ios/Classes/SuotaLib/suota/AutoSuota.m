/*
 *******************************************************************************
 *
 * Copyright (C) 2019-2020 Dialog Semiconductor.
 * This computer program includes Confidential, Proprietary Information
 * of Dialog Semiconductor. All Rights Reserved.
 *
 *******************************************************************************
 */

#import "AutoSuota.h"
#import "SuotaBluetoothManager.h"
#import "SuotaFile.h"
#import "SuotaProfile.h"
#import "SuotaLibLog.h"

@implementation AutoSuota

static NSString* const TAG = @"AutoSuota";
static int const CONNECTION_TIMEOUT_MILLIS = 15000;

- (instancetype) initWithSuotaFile:(SuotaFile*)suotaFile peripheral:(CBPeripheral*)peripheral delegate:(id<BaseSuotaDelegate>)delegate {
    self = [super init];
    if (!self)
        return nil;
    self.suotaFile = suotaFile;
    self.peripheral = peripheral;
    self.delegate = delegate;
    return self;
}

- (void) run:(UIViewController*)suotaViewController {
    self.suotaManager = [[SuotaManager alloc] initWithPeripheral:self.peripheral suotaManagerDelegate:self];
    self.suotaManager.suotaFile = self.suotaFile;
    self.suotaManager.suotaViewController = suotaViewController;
    [self.suotaManager connect];
}

#pragma mark - SuotaManagerDelegate

- (void) onFailure:(int)errorCode {
    if (self.delegate)
        [self.delegate displayErrorDialog:errorCode];
}

- (void) onConnectionStateChange:(enum SuotaManagerStatus)newStatus {
    if (newStatus == DISCONNECTED && self.delegate)
        [self.delegate deviceDisconnected];
}

- (void) onServicesDiscovered {
}

- (void) onCharacteristicRead:(enum CharacteristicGroup)characteristicGroup characteristic:(CBCharacteristic*)characteristic {
}

- (void) onDeviceInfoReadCompleted:(enum DeviceInfoReadStatus)status {
}

- (void) onDeviceReady {
    if (self.delegate)
        [self.delegate startSuota];
}

- (void) onSuotaLog:(enum SuotaProtocolState)state type:(enum SuotaLogType)type log:(NSString*)log {
    if (self.delegate)
        [self.delegate appendToLogcat:log];
}

- (void) onChunkSend:(int)chunkCount totalChunks:(int)totalChunks chunk:(int)chunk block:(int)block blockChunks:(int)blockChunks totalBlocks:(int)totalBlocks {
    if (self.delegate)
        [self.delegate updateCurrentlySendingInfo:chunkCount totalChunks:totalChunks chunk:chunk block:block blockChunks:blockChunks totalBlocks:totalBlocks];
}

- (void) updateSpeedStatistics:(double)current max:(double)max min:(double)min avg:(double)avg {
    if (SuotaLibConfig.CALCULATE_STATISTICS && self.delegate)
        [self.delegate updateSpeedStatistics:current max:max min:min avg:avg];
}

- (void) onBlockSent:(int)block totalBlocks:(int)totalBlocks {
}

- (void) updateCurrentSpeed:(double)currentSpeed {
}

- (void) onUploadProgress:(float)percent {
    if (self.delegate)
        [self.delegate updateProgress:percent];
}

- (void) onSuccess:(double)totalElapsedSeconds imageUploadElapsedSeconds:(double)imageUploadElapsedSeconds {
    if (!self.delegate)
        return;
    [self.delegate onSuccess:totalElapsedSeconds imageUploadElapsedSecs:imageUploadElapsedSeconds];
    if (!SuotaLibConfig.AUTO_REBOOT)
        [self.delegate onSuotaFinished];
}

- (void) onRebootSent {
    if (!self.delegate)
        return;
    [self.delegate rebootSent];
    if (SuotaLibConfig.AUTO_REBOOT)
        [self.delegate onSuotaFinished];
}

@end
