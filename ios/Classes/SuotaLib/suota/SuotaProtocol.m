/*
 *******************************************************************************
 *
 * Copyright (C) 2019-2020 Dialog Semiconductor.
 * This computer program includes Confidential, Proprietary Information
 * of Dialog Semiconductor. All Rights Reserved.
 *
 *******************************************************************************
 */

#import "SuotaProtocol.h"
#import "MemoryDeviceOperation.h"
#import "SendChunkOperation.h"
#import "SendEndSignalOperation.h"
#import "SuotaFile.h"
#import "SuotaLibConfig.h"
#import "SuotaLibLog.h"
#import "SuotaManager.h"
#import "SuotaProfile.h"

@implementation SpeedStatistics

- (instancetype) init {
    self = [super init];
    if (!self)
        return nil;
    self.speeds = [NSMutableArray array];
    [self reset];
    return self;
}

- (void) reset {
    self.bytesSent = 0;
    [self.speeds removeAllObjects];
    self.sum = 0;
    self.max = DBL_MIN;
    self.min = DBL_MAX;
}

- (void) update:(int)size speed:(double)speed {
    self.bytesSent += size;
    self.uploadAvg = self.bytesSent / (([[NSDate date] timeIntervalSince1970] * 1000 - self.uploadStartTime) / 1000.);
    [self.speeds addObject:@(speed)];
    self.sum += speed;
    if (self.max < speed)
        self.max = speed;
    if (self.min > speed)
        self.min = speed;
}

- (double) avg {
    return self.sum / self.speeds.count;
}

@end

@implementation SuotaProtocol

static NSString* const TAG = @"SuotaProtocol";

static int const PROGRESS_UPDATE_MILLIS = 1000;

- (instancetype) initWithManager:(SuotaManager*)suotaManager {
    self = [super init];
    if (!self)
        return nil;
    self.suotaManager = suotaManager;
    self.suotaManagerDelegate = suotaManager.suotaManagerDelegate;
    if (SuotaLibConfig.CALCULATE_STATISTICS)
        self.statistics = [[SpeedStatistics alloc] init];
    [self reset];
    return self;
}

- (void) start {
    [self reset];
    self.suotaRunning = true;
    if (SuotaLibLog.PROTOCOL || SuotaLibConfig.NOTIFY_SUOTA_LOG) {
        NSString* uploadSize = [NSString stringWithFormat:@"Upload size: %d bytes", self.suotaFile.uploadSize];
        NSString* blockSize = [NSString stringWithFormat:@"Block size: %d bytes", self.suotaFile.blockSize];
        NSString* chunkSize = [NSString stringWithFormat:@"Chunk size: %d bytes", self.suotaFile.chunkSize];
        NSString* totalBlocks = [NSString stringWithFormat:@"Total blocks: %d", self.suotaFile.totalBlocks];
        NSString* totalChunks = [NSString stringWithFormat:@"Total chunks: %d", self.suotaFile.totalChunks];
        NSString* chunksPerBlock = [NSString stringWithFormat:@"Chunks per block: %d", self.suotaFile.chunksPerBlock];
        NSString* firmwareCrc = [NSString stringWithFormat:@"Firmware CRC: %#04x", self.suotaFile.crc];

        SuotaLogOpt(SuotaLibLog.PROTOCOL, TAG, @"Start SUOTA");
        SuotaLogOpt(SuotaLibLog.PROTOCOL, TAG, @"%@", uploadSize);
        SuotaLogOpt(SuotaLibLog.PROTOCOL, TAG, @"%@", blockSize);
        SuotaLogOpt(SuotaLibLog.PROTOCOL, TAG, @"%@", chunkSize);
        SuotaLogOpt(SuotaLibLog.PROTOCOL, TAG, @"%@", totalBlocks);
        SuotaLogOpt(SuotaLibLog.PROTOCOL, TAG, @"%@", totalChunks);
        SuotaLogOpt(SuotaLibLog.PROTOCOL, TAG, @"%@", chunksPerBlock);
        SuotaLogOpt(SuotaLibLog.PROTOCOL, TAG, @"%@", firmwareCrc);

        if (SuotaLibConfig.NOTIFY_SUOTA_LOG)
            [self.suotaManagerDelegate onSuotaLog:self.state type:INFO log:[NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%@\n%@\n%@\n", uploadSize, blockSize, chunkSize, totalBlocks, totalChunks, chunksPerBlock, firmwareCrc]];
    }
    [self execute];
}

- (BOOL) isRunning {
    return self.suotaRunning;
}

- (void) notifyForSendingChunk:(SendChunkOperation*)sendChunk {
    self.lastChunk = sendChunk;

    // Block notification timeout
    if (SuotaLibConfig.UPLOAD_TIMEOUT > 0) {
        if (sendChunk.isLastChunk)
            self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:((double)SuotaLibConfig.UPLOAD_TIMEOUT / 1000.0) target:self selector:@selector(timeout:) userInfo:nil repeats:false];
    }
    
    int block = sendChunk.block;
    int chunk = sendChunk.chunk;
    
    if (SuotaLibLog.CHUNK || (SuotaLibConfig.NOTIFY_SUOTA_LOG_CHUNK && SuotaLibConfig.NOTIFY_SUOTA_LOG)) {
        NSString* msg = [NSString stringWithFormat:@"Send block %d, chunk %d of %d (%d of %d), size %lu", block + 1, chunk + 1, [self.suotaFile getBlockChunks:block], sendChunk.chunkCount, self.suotaFile.totalChunks, (unsigned long)sendChunk.value.length];
        SuotaLogOpt(SuotaLibLog.CHUNK, TAG, @"%@", msg);
        if (SuotaLibConfig.NOTIFY_SUOTA_LOG_CHUNK && SuotaLibConfig.NOTIFY_SUOTA_LOG)
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.suotaManagerDelegate onSuotaLog:self.state type:CHUNK log:msg];
            });
    }

    if (SuotaLibConfig.CALCULATE_STATISTICS)
        if (!chunk)
            self.currentBlockStartTime = [[NSDate date] timeIntervalSince1970] * 1000;
}

- (void) notifyForSendingMemoryDevice {
    self.memoryDeviceSent = true;
}

- (void) notifyForSendingEndSignal {
    self.endSignalSent = true;
}

- (void) destroy {
    SuotaLog(TAG, @"Destroy");
    self.suotaRunning = false;
    if (self.currentSpeedTimer && self.currentSpeedTimer.isValid)
        [self.currentSpeedTimer invalidate];
    if (SuotaLibConfig.UPLOAD_TIMEOUT > 0 && self.timeoutTimer && self.timeoutTimer.isValid)
        [self.timeoutTimer invalidate];
}

- (double) uploadAvg {
    return self.statistics ? self.statistics.uploadAvg : -1;
}

- (double) avg {
    return self.statistics ? self.statistics.avg : -1;
}

- (double) max {
    return self.statistics ? self.statistics.max : -1;
}

- (double) min {
    return self.statistics ? self.statistics.min : -1;
}

- (void) onCharacteristicChanged:(int)value {
    if (!self.suotaRunning)
        return;

    SuotaLogOpt(SuotaLibLog.PROTOCOL, TAG, @"Service status: %@ (state = %@)", SuotaProfile.notificationValueDescriptionList[@(value)] ? SuotaProfile.notificationValueDescriptionList[@(value)] : [NSString stringWithFormat:@"%#04x", value], SuotaProfile.suotaStateDescriptionList[@(self.state)] ? SuotaProfile.suotaStateDescriptionList[@(self.state)] : @(self.state));
    
    if (value == IMAGE_STARTED) {
        [self onImageStarted];
    } else if (value == SERVICE_STATUS_OK) {
        [self onStatusOk];
    } else {
        [self onError:value];
    }
}

- (void) onCharacteristicWrite:(CBCharacteristic*)characteristic {
    if (!self.suotaRunning)
        return;
    CBUUID* uuid = characteristic.UUID;
    
    if (SuotaLibConfig.PROTOCOL_DEBUG) {
        // Memory device write callback may come after the image started notification, in which case the state will be SET_GPIO_MAP, not SET_MEMORY_DEVICE.
        if ((![uuid isEqual:SuotaProfile.SUOTA_MEM_DEV_UUID] && ![uuid isEqual:SuotaProfile.SUOTA_GPIO_MAP_UUID] && ![uuid isEqual:SuotaProfile.SUOTA_PATCH_LEN_UUID] && ![uuid isEqual:SuotaProfile.SUOTA_PATCH_DATA_UUID])
            || ([uuid isEqual:SuotaProfile.SUOTA_MEM_DEV_UUID] && self.state != SET_MEMORY_DEVICE && self.state != SET_GPIO_MAP && self.state != END_SIGNAL)
            || ((self.state == SET_MEMORY_DEVICE || self.state == END_SIGNAL) && ![uuid isEqual:SuotaProfile.SUOTA_MEM_DEV_UUID])
            || ((self.state == SET_GPIO_MAP) ^ [uuid isEqual:SuotaProfile.SUOTA_GPIO_MAP_UUID] && (self.state != SET_GPIO_MAP || ![uuid isEqual:SuotaProfile.SUOTA_MEM_DEV_UUID]))
            || (self.state == SEND_BLOCK) ^ ([uuid isEqual:SuotaProfile.SUOTA_PATCH_LEN_UUID] || [uuid isEqual:SuotaProfile.SUOTA_PATCH_DATA_UUID])) {
            SuotaLog(TAG, @"Unexpected characteristic write on state %@: %@", SuotaProfile.suotaStateDescriptionList[@(self.state)] ? SuotaProfile.suotaStateDescriptionList[@(self.state)] : @(self.state), uuid);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self suotaProtocolError];
            });
            return;
        }
    }
    
    if (SuotaLibLog.PROTOCOL) {
        if ([uuid isEqual:SuotaProfile.SUOTA_MEM_DEV_UUID]) {
            if (self.state == SET_MEMORY_DEVICE || self.state == SET_GPIO_MAP)
                SuotaLog(TAG, @"Memory device set");
            else if (self.state == END_SIGNAL)
                SuotaLog(TAG, @"End signal sent");
        } else if ([uuid isEqual:SuotaProfile.SUOTA_PATCH_LEN_UUID]) {
            SuotaLog(TAG, @"Patch length set");
        }
    }

    if ([uuid isEqual:SuotaProfile.SUOTA_GPIO_MAP_UUID]) {
        SuotaLogOpt(SuotaLibLog.PROTOCOL, TAG, @"GPIO map set");
        [self moveToNextState];
        [self execute];
    } else if ([uuid isEqual:SuotaProfile.SUOTA_PATCH_LEN_UUID]) {
        [self sendBlock];
    } else if ([uuid isEqual:SuotaProfile.SUOTA_PATCH_DATA_UUID]) {
        SuotaLogOpt(SuotaLibLog.CHUNK, TAG, @"Patch data write, chunk %d", self.lastChunk.chunkCount);
        if (SuotaLibConfig.NOTIFY_CHUNK_SEND)
            [self notifyChunkSend];
    }
}

- (void) onDescriptorWrite:(CBCharacteristic*)characteristic {
    if (!self.suotaRunning)
        return;
    
    if (SuotaLibConfig.PROTOCOL_DEBUG) {
        if (self.state != ENABLE_NOTIFICATIONS || ![characteristic.UUID isEqual:SuotaProfile.SUOTA_SERV_STATUS_UUID]) {
            SuotaLog(TAG, @"Unexpected descriptor write on state %@: %@", SuotaProfile.suotaStateDescriptionList[@(self.state)] ? SuotaProfile.suotaStateDescriptionList[@(self.state)] : @(self.state), characteristic.UUID.UUIDString);
            [self suotaProtocolError];
            return;
        }
    }

    SuotaLogOpt(SuotaLibLog.PROTOCOL, TAG, @"Status notifications enabled");
    [self moveToNextState];
    [self execute];
}

- (void) moveToNextState {
    if (SuotaLibConfig.PROTOCOL_DEBUG && self.state == END_SIGNAL)
        [self suotaProtocolError];

    [self onPostExecute];
    switch (self.state) {
        case ENABLE_NOTIFICATIONS:
            self.state = SET_MEMORY_DEVICE;
            break;
        case SET_MEMORY_DEVICE:
            self.state = SET_GPIO_MAP;
            break;
        case SET_GPIO_MAP:
            self.state = SEND_BLOCK;
            break;
        case SEND_BLOCK:
            if ([self.suotaFile isLastBlock:self.currentBlock])
                self.state = END_SIGNAL;
            break;
    }
}

- (void) execute {
    switch (self.state) {
        case ENABLE_NOTIFICATIONS:
            [self enableNotifications];
            break;
        case SET_MEMORY_DEVICE:
            [self setMemoryDevice];
            break;
        case SET_GPIO_MAP:
            [self setGpioMap];
            break;
        case SEND_BLOCK:
            [self prepareSendBlock];
            break;
        case END_SIGNAL:
            [self sendEndSignal];
            break;
    }
}

- (void) onPostExecute {
    if (self.state == SEND_BLOCK)
        [self onBlockSent];
}

- (void) reset {
    self.suotaFile = self.suotaManager.suotaFile;
    self.suotaRunning = false;
    self.memoryDeviceSent = false;
    self.endSignalSent = false;
    self.currentBlock = -1;
    self.lastChunk = nil;
    if (SuotaLibConfig.CALCULATE_STATISTICS)
        [self.statistics reset];
    self.state = ENABLE_NOTIFICATIONS;
}

- (void) onImageStarted {
    if (self.state == SET_MEMORY_DEVICE && self.memoryDeviceSent) {
        if (SuotaLibConfig.UPLOAD_TIMEOUT > 0)
            [self.timeoutTimer invalidate];
        self.memoryDeviceSent = false; // detect future faulty notification
        SuotaLogOpt(SuotaLibLog.PROTOCOL, TAG, @"Image started notification");
        [self moveToNextState];
        [self execute];
    } else {
        [self suotaProtocolError];
    }
}

// Occurs when a block has completely been sent and after end signal
- (void) onStatusOk {
    if (self.state == SEND_BLOCK) {
        if (SuotaLibConfig.UPLOAD_TIMEOUT > 0)
            [self.timeoutTimer invalidate];
        
        if (!self.lastChunk || !self.lastChunk.isLastChunk) {
            [self suotaProtocolError];
            return;
        }
        self.lastChunk = nil; // detect future faulty notification

        [self moveToNextState];
        [self execute];
    } else if (self.state == END_SIGNAL && self.endSignalSent) {
        if (SuotaLibConfig.UPLOAD_TIMEOUT > 0)
            [self.timeoutTimer invalidate];
        SuotaLogOpt(SuotaLibLog.PROTOCOL, TAG, @"End Signal Notification");
        self.endSignalSent = false; // detect future faulty notification
        [self onPostExecute];
        self.elapsedTime = [[NSDate date] timeIntervalSince1970] * 1000 - self.startTime;
        if (SuotaLibLog.PROTOCOL || SuotaLibConfig.NOTIFY_SUOTA_LOG) {
            NSString* msg = [NSString stringWithFormat: @"Update completed in %.3f seconds", self.elapsedTime / 1000.];
            SuotaLogOpt(SuotaLibLog.PROTOCOL, TAG, @"%@", msg);
            if (SuotaLibConfig.NOTIFY_SUOTA_LOG)
                [self.suotaManagerDelegate onSuotaLog:self.state type:INFO log:msg];
        }

        self.suotaRunning = false;
        [self.suotaManager onSuotaProtocolSuccess];
    } else {
        [self suotaProtocolError];
    }
}

- (void) onError:(int)error {
    if (SuotaLibConfig.UPLOAD_TIMEOUT > 0 && self.timeoutTimer && self.timeoutTimer.isValid)
        [self.timeoutTimer invalidate];
    NSString* msg = [NSString stringWithFormat:@"Error: %d, %@", error, SuotaProfile.suotaErrorCodeList[@(error)]];
    SuotaLog(TAG, @"%@", msg);
    self.suotaRunning = false;
    self.state = ERROR;
    [self.suotaManagerDelegate onFailure:error];
    if (SuotaLibConfig.NOTIFY_SUOTA_LOG)
        [self.suotaManagerDelegate onSuotaLog:ERROR type:INFO log:msg];
    [self.suotaManager destroy];
}

- (void) suotaProtocolError {
    if (SuotaLibConfig.UPLOAD_TIMEOUT > 0 && self.timeoutTimer && self.timeoutTimer.isValid)
        [self.timeoutTimer invalidate];
    SuotaLog(TAG, @"SUOTA protocol error");
    self.suotaRunning = false;
    self.state = ERROR;
    [self.suotaManagerDelegate onFailure:PROTOCOL_ERROR];
    if (SuotaLibConfig.NOTIFY_SUOTA_LOG)
        [self.suotaManagerDelegate onSuotaLog:ERROR type:INFO log:@"SUOTA protocol error"];
    [self.suotaManager destroy];
}

- (void) notifyChunkSend {
    SendChunkOperation* lastChunk = self.lastChunk;
    int block = lastChunk.block;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.suotaManagerDelegate onChunkSend:lastChunk.chunkCount totalChunks:self.suotaFile.totalChunks chunk:lastChunk.chunk + 1 block:block + 1 blockChunks:[self.suotaFile getBlockChunks:block] totalBlocks:self.suotaFile.totalBlocks];
    });
}

- (void) notifyBlockSent {
    [self.suotaManagerDelegate onBlockSent:self.currentBlock + 1 totalBlocks:self.suotaFile.totalBlocks];
}

- (void) notifyUploadProgress {
    [self.suotaManagerDelegate onUploadProgress:((float)(self.currentBlock + 1)) / self.suotaFile.totalBlocks * 100];
}

- (void) timeout:(NSTimer*)timer {
    dispatch_async(dispatch_get_main_queue(), ^{
        SuotaLog(TAG, @"Upload timeout");
        [self onError:UPLOAD_TIMEOUT];
    });
}

- (void) enableNotifications {
    SuotaLogOpt(SuotaLibLog.PROTOCOL, TAG, @"Enable status notifications");
    if (SuotaLibConfig.NOTIFY_SUOTA_LOG)
        [self.suotaManagerDelegate onSuotaLog:self.state type:INFO log:@"Enable status notifications"];
    [self.suotaManager executeOperation:[[GattOperation alloc] initWithDescriptorForNotificationStatus:self.suotaManager.serviceStatusCharacteristic notificationStatus:true]];
}

- (void) setMemoryDevice {
    int memoryDevice = self.suotaManager.memoryDevice;
    self.startTime = [[NSDate date] timeIntervalSince1970] * 1000;

    if (SuotaLibLog.PROTOCOL || SuotaLibConfig.NOTIFY_SUOTA_LOG) {
        NSString* msg = [NSString stringWithFormat:@"Set memory device: %#010x", memoryDevice];
        SuotaLogOpt(SuotaLibLog.PROTOCOL, TAG, @"%@", msg);
        if (SuotaLibConfig.NOTIFY_SUOTA_LOG)
            [self.suotaManagerDelegate onSuotaLog:self.state type:INFO log:msg];
    }
    
    // Image started notification timeout
    if (SuotaLibConfig.UPLOAD_TIMEOUT > 0)
        self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:((double)SuotaLibConfig.UPLOAD_TIMEOUT / 1000.0) target:self selector:@selector(timeout:) userInfo:nil repeats:false];
    [self.suotaManager executeOperation:[[MemoryDeviceOperation alloc] initWithProtocol:self characteristic:self.suotaManager.memDevCharacteristic value:memoryDevice]];
}

- (void) setGpioMap {
    int gpioMap = self.suotaManager.gpioMap;
    if (SuotaLibLog.PROTOCOL || SuotaLibConfig.NOTIFY_SUOTA_LOG) {
        NSString* msg = [NSString stringWithFormat:@"Set Gpio Map: %#010x", gpioMap];
        SuotaLogOpt(SuotaLibLog.PROTOCOL, TAG, @"%@", msg);
        if (SuotaLibConfig.NOTIFY_SUOTA_LOG)
            [self.suotaManagerDelegate onSuotaLog:self.state type:INFO log:msg];
    }
    [self.suotaManager executeOperation:[[GattOperation alloc] initWithType:WRITE characteristic:self.suotaManager.gpioMapCharacteristic value:gpioMap]];
}

- (void) prepareSendBlock {
    self.currentBlock++;
    self.lastChunk = nil;
    
    if (!self.currentBlock) {
        SuotaLogOpt(SuotaLibLog.PROTOCOL, TAG, @"Upload started");
        if (SuotaLibConfig.NOTIFY_SUOTA_LOG)
            [self.suotaManagerDelegate onSuotaLog:self.state type:INFO log:@"Upload started"];
        self.uploadStartTime = [[NSDate date] timeIntervalSince1970] * 1000;
        
        if (SuotaLibConfig.CALCULATE_STATISTICS) {
            self.statistics.uploadStartTime = self.uploadStartTime;
            self.bytesSent = 0;
            self.currentSpeedTimer = [NSTimer scheduledTimerWithTimeInterval:((double) PROGRESS_UPDATE_MILLIS / 1000.0) target:self selector:@selector(updateCurrentSpeed:) userInfo:nil repeats:true];
        }
        [self sendPatchLength:self.suotaFile.blockSize];
    } else if ([self.suotaFile isLastBlock:self.currentBlock] && self.suotaFile.isLastBlockShorter) {
        [self sendPatchLength:self.suotaFile.lastBlockSize];
    } else {
        [self sendBlock];
    }
}

- (void) sendPatchLength:(int)blockSize {
    if (SuotaLibLog.PROTOCOL || SuotaLibConfig.NOTIFY_SUOTA_LOG) {
        NSString* msg = [NSString stringWithFormat:@"Set patch length: %d", blockSize];
        SuotaLogOpt(SuotaLibLog.PROTOCOL, TAG, @"%@", msg);
        if (SuotaLibConfig.NOTIFY_SUOTA_LOG)
            [self.suotaManagerDelegate onSuotaLog:self.state type:INFO log:msg];
    }
    [self.suotaManager executeOperation:[[GattOperation alloc] initWithCharacteristic:self.suotaManager.patchLengthCharacteristic value:(uint16_t)blockSize]];
}

- (void) sendBlock {
    SuotaLogOpt(SuotaLibLog.BLOCK, TAG, @"Current block: %d of %d", self.currentBlock + 1, self.suotaFile.totalBlocks);
    
    NSArray<NSData*>* block = [self.suotaFile getBlock:self.currentBlock];
    int chunk = 0;
    int chunkCount = self.currentBlock * self.suotaFile.chunksPerBlock + 1;
    for (NSData* chunkData in block) {
        SuotaLogOpt(SuotaLibLog.CHUNK, TAG, @"Queue block %d, chunk %d", self.currentBlock + 1, chunk + 1);
        [self.suotaManager enqueueSendChunkOperation:[[SendChunkOperation alloc] initWithSuotaProtocol:self characteristic:self.suotaManager.patchDataCharacteristic valueData:chunkData chunkCount:chunkCount chunk:chunk block:self.currentBlock isLastChunk:[self.suotaFile isLastChunk:self.currentBlock chunk:chunk]]];
        chunk++;
        chunkCount++;
    }
}

- (void) onBlockSent {
    BOOL lastBlock = [self.suotaFile isLastBlock:self.currentBlock];
    if (lastBlock)
        self.uploadElapsedTime = [[NSDate date] timeIntervalSince1970] * 1000 - self.uploadStartTime;

    if (SuotaLibConfig.CALCULATE_STATISTICS) {
        double elapsed = ([[NSDate date] timeIntervalSince1970] * 1000 - self.currentBlockStartTime) / 1000.;
        int size = [self.suotaFile getBlockSize:self.currentBlock];
        double speed = size / elapsed;
        
        if (SuotaLibLog.BLOCK || (SuotaLibConfig.NOTIFY_SUOTA_LOG_BLOCK && SuotaLibConfig.NOTIFY_SUOTA_LOG)) {
            NSString* msg = [NSString stringWithFormat:@"Block sent: %d, %.3f seconds, %d B/s", self.currentBlock + 1, elapsed, (int) speed];
            SuotaLogOpt(SuotaLibLog.BLOCK, TAG, @"%@", msg);
            if (SuotaLibConfig.NOTIFY_SUOTA_LOG_BLOCK && SuotaLibConfig.NOTIFY_SUOTA_LOG)
                [self.suotaManagerDelegate onSuotaLog:self.state type:BLOCK log:msg];
        }
        
        self.bytesSent += size;
        [self.statistics update:size speed:speed];
        [self.suotaManagerDelegate updateSpeedStatistics:speed max:self.statistics.max min:self.statistics.min avg:!lastBlock ? self.statistics.uploadAvg : self.suotaFile.uploadSize / (self.uploadElapsedTime / 1000.)];
    } else if (SuotaLibLog.BLOCK || (SuotaLibConfig.NOTIFY_SUOTA_LOG_BLOCK && SuotaLibConfig.NOTIFY_SUOTA_LOG)) {
               NSString* msg = [NSString stringWithFormat:@"Block sent: %d", self.currentBlock + 1];
               SuotaLogOpt(SuotaLibLog.BLOCK, TAG, @"%@", msg);
               if (SuotaLibConfig.NOTIFY_SUOTA_LOG_BLOCK && SuotaLibConfig.NOTIFY_SUOTA_LOG)
                   [self.suotaManagerDelegate onSuotaLog:self.state type:BLOCK log:msg];
    }

    if (SuotaLibConfig.NOTIFY_BLOCK_SENT)
        [self notifyBlockSent];
    if (SuotaLibConfig.NOTIFY_UPLOAD_PROGRESS)
        [self notifyUploadProgress];
    if (SuotaLibLog.PROTOCOL || SuotaLibConfig.NOTIFY_SUOTA_LOG) {
        if (lastBlock) {
            NSString* msg = [NSString stringWithFormat:@"Upload completed in %.3f seconds", self.uploadElapsedTime / 1000.0];
            SuotaLogOpt(SuotaLibLog.PROTOCOL, TAG, @"%@", msg);
            if (SuotaLibConfig.NOTIFY_SUOTA_LOG)
                [self.suotaManagerDelegate onSuotaLog:self.state type:INFO log:msg];
        }
    }
}

- (void) sendEndSignal {
    SuotaLogOpt(SuotaLibLog.PROTOCOL, TAG, @"Send SUOTA end signal");
    if (SuotaLibConfig.NOTIFY_SUOTA_LOG)
        [self.suotaManagerDelegate onSuotaLog:self.state type:INFO log:@"Send end signal"];
    // End signal notification timeout
    if (SuotaLibConfig.UPLOAD_TIMEOUT > 0)
        self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:((double)SuotaLibConfig.UPLOAD_TIMEOUT / 1000.0) target:self selector:@selector(timeout:) userInfo:nil repeats:false];
    [self.suotaManager executeOperation:[[SendEndSignalOperation alloc] initWithSuotaProtocol:self characteristic:self.suotaManager.memDevCharacteristic]];
}

- (void) updateCurrentSpeed:(NSTimer*)timer {
    [self.suotaManagerDelegate updateCurrentSpeed:self.bytesSent];
    self.bytesSent = 0;
}

@end
