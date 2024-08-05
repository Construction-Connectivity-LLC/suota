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
 @header AutoSuota.h
 @brief Header file for the AutoSuota class.
 
 This header file contains method and property declaration for the AutoSuota class. It also contains the declaration for BaseSuotaDelegate protocol.
 
 @copyright 2019 Dialog Semiconductor
 */

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <UIKit/UIKit.h>
#import "SuotaLibConfig.h"
#import "SuotaManager.h"

@class SuotaFile;

/*!
 *  @protocol BaseSuotaDelegate
 *
 *  @discussion The {@link suotaViewController} must adopt the <code>BaseSuotaDelegate</code> protocol. The methods allow for information on the SUOTA process.
 *
 */
@protocol BaseSuotaDelegate

/*!
 * @method startSuota
 *
 * @discussion Triggered when the {@link onDeviceReady} method gets triggered.
 */
- (void) startSuota;

/*!
 * @method appendToLogcat:
 *
 * @param log Message to be appended to the log.
 *
 * @discussion Triggered when the {@link onSuotaLog:type:log:}
 * method gets triggered.
 */
- (void) appendToLogcat:(NSString*)log;

/*!
 * @method onSuccess:imageUploadElapsedSecs:
 *
 * @param totalElapsedSecs The total elapsed millis while SUOTA was running.
 * @param imageUploadElapsedSecs The total elapsed millis while the actual image was being sent.
 *
 * @discussion Triggered when the {@link onSuccess:imageUploadElapsedSeconds:}
 * method gets triggered.
 */
- (void) onSuccess:(double)totalElapsedSecs imageUploadElapsedSecs:(double)imageUploadElapsedSecs;

/*!
 * @method updateCurrentlySendingInfo:totalChunks:chunk:block:blockChunks:totalBlocks:
 *
 * @param chunkCount Chunk count of total chunks.
 * @param totalChunks Total chunks.
 * @param chunk Chunk count of current block.
 * @param block Block count.
 * @param blockChunks Total chunks in current block.
 * @param totalBlocks Total blocks.
 *
 * @discussion Triggered when the {@link onChunkSend:totalChunks:chunk:block:blockChunks:totalBlocks:}
 * method gets triggered.
 */
- (void) updateCurrentlySendingInfo:(int)chunkCount totalChunks:(int)totalChunks chunk:(int)chunk block:(int)block blockChunks:(int)blockChunks totalBlocks:(int)totalBlocks;

/*!
 * @method updateProgress:
 *
 * @param percent Update progress percent. Value of 1.0 corresponds to 100%.
 *
 * @discussion Triggered when the {@link onUploadProgress:}
 * method gets triggered.
 */
- (void) updateProgress:(float)percent;

/*!
 * @method rebootSent:
 *
 * @discussion Triggered when the {@link onRebootSent}
 * method gets triggered.
 */
- (void) rebootSent;

/*!
 * @method displayErrorDialog:
 *
 * @param errorSuotaLibCode Error codes can be found at {@link SuotaErrors} and {@link ApplicationErrors}.
 *
 * @discussion Triggered when the {@link onFailure:}
 * method gets triggered.
 */
- (void) displayErrorDialog:(int)errorSuotaLibCode;

/*!
 * @method displayErrorDialogString:
 *
 * @param errorMsg String error message.
 *
 * @discussion Overload of the above method.
 */
- (void) displayErrorDialogString:(NSString*)errorMsg;

/*!
 * @method deviceDisconnected:
 *
 * @discussion Triggered when the {@link onConnectionStateChange:}
 * callback gets triggered due to BLE device disconnection.
 */
- (void) deviceDisconnected;

/*!
 * @method onSuotaFinished:
 *
 * @discussion Triggered when the SUOTA process is finished.
 */
- (void) onSuotaFinished;

/*!
 * @method updateSpeedStatistics:max:min:avg:
 *
 * @param current Current block speed (bytes per second).
 * @param max Max block speed (bytes per second).
 * @param min Min block speed (bytes per second).
 * @param avg Average speed (bytes per second).
 *
 * @discussion Triggered every 500ms, when the {@link CALCULATE_STATISTICS} is <code>true</code>
 * in order to send speed statistics to the app.
 */
- (void) updateSpeedStatistics:(double)current max:(double)max min:(double)min avg:(double)avg;

@end

/*!
 * @class AutoSuota
 *
 * @brief Helper class that initializes and starts a SUOTA process.
 *
 * @discussion Initializes a {@link SuotaManager} object and starts the SUOTA process. All the necessary objects are set at the object initialization. Conforms to the {@link SuotaManagerDelegate} in order to receive update for the process. Defines the {@link BaseSuotaDelegate} protocol in order to send necessary information at the {@link suotaViewController} parameter.
 *
 */
@interface AutoSuota : NSObject <SuotaManagerDelegate>

@property id<BaseSuotaDelegate> delegate;
@property SuotaFile* suotaFile;
@property CBPeripheral* peripheral;
@property SuotaManager* suotaManager;
@property NSTimer* connectTimer;

/*!
 * @method initWithSuotaFile:peripheral:delegate:
 *
 * @param suotaFile {@link SuotaFile} object that contains the SUOTA patch.
 * @param peripheral The BLE device to perform the SUOTA.
 * @param delegate An object that conforms to the {@link BaseSuotaDelegate} protocol.
 *
 * @discussion Creates a new {@link AutoSuota} object. Needs an object that conforms to the {@link BaseSuotaDelegate} protocol in order to be informed about the SUOTA process.
 */
- (instancetype) initWithSuotaFile:(SuotaFile*)suotaFile peripheral:(CBPeripheral*)peripheral delegate:(id<BaseSuotaDelegate>)delegate;

/*!
 * @method run:
 *
 * @param suotaViewController A {@link UIViewController} object used to show alert dialogs when needed.
 *
 * @discussion Initializes and starts the SUOTA process. When the device is connected and ready to start the SUOTA file transfer the {@link startSuota} method will be called on the delegate object.
 */
- (void) run:(UIViewController*)suotaViewController;

@end
