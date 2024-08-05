#import "SuotaPlugin.h"
#import "SuotaLib/SuotaLib.h"

@implementation SuotaPlugin

- (instancetype)init {
    self = [super init];
    if (self) {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        _discoveredPeripherals = [NSMutableDictionary dictionary];
        
        _targetPeripheral = nil;
        _flutterResult = nil;
        _targetRemoteId = nil;
        
    }
    return self;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"renesas_suota"
                                     binaryMessenger:[registrar messenger]];
    
    FlutterEventChannel* progressChannel = [FlutterEventChannel
        eventChannelWithName:@"renesas_suota/events"
              binaryMessenger:[registrar messenger]];
    SuotaPlugin* instance = [[SuotaPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    [progressChannel setStreamHandler:instance];
}
#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBManagerStatePoweredOn) {
        // If Bluetooth was off but now is on, start scanning again
        if (self.targetRemoteId != nil) {
            [self.centralManager scanForPeripheralsWithServices:nil options:nil];
        }
    } else {
        // Handle other states
        if (self.flutterResult != nil) {
            self.flutterResult([FlutterError errorWithCode:@"BLUETOOTH_OFF"
                                                   message:@"Bluetooth is powered off"
                                                   details:nil]);
            self.flutterResult = nil;
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSLog(@"SUOTA Found some peripheral with remoteId: %@", peripheral.identifier.UUIDString);
    if ([peripheral.identifier.UUIDString isEqualToString:self.targetRemoteId]) {
        NSLog(@"SUOTA Found peripheral 1 with remoteId: %@", self.targetRemoteId);
        self.targetPeripheral = peripheral;
//        [self.centralManager stopScan];
        
        NSLog(@"SUOTA Found peripheral with remoteId: %@", self.targetRemoteId);
        
        [self.suotaManager initWithPeripheral:self.targetPeripheral suotaManagerDelegate:self];
        [self.centralManager stopScan];
        [self.suotaManager connect];
        //    if (self.flutterResult != nil) {
        //      self.flutterResult([NSString stringWithFormat:@"Found device: %@", peripheral.name]);
        //      self.flutterResult = nil;
        //    }
    }
}

#pragma mark - CBPeripheralDelegate

- (void)installUpdate:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString *path = call.arguments[@"path"];
    NSString *fileName = call.arguments[@"fileName"];
    NSString *remoteId = call.arguments[@"remoteId"];
    
    self.flutterResult = result;
    self.filePath = path;
    self.fileName = fileName;
    
    NSLog(@"SUOTA Received getBluetoothDeviceById call with remoteId: %@", remoteId);
    if (self.centralManager.state == CBManagerStatePoweredOn) {
        NSLog(@"SUOTA Started scanForPeripheralsWithServices");
        self.targetRemoteId = remoteId;
        [self.centralManager scanForPeripheralsWithServices:nil options:nil];
        self.suotaManager = [SuotaManager alloc];
        self.suotaManager.bluetoothManager.bluetoothManager = self.centralManager;
    } else {
        result([FlutterError errorWithCode:@"DEVICE_NOT_FOUND"
                                   message:@"Device not found"
                                   details:nil]);
    }
    
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSLog(@"SUOTA handleMethodCall call with method: %@", call.method);
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    } if ([@"installUpdate" isEqualToString:call.method]) {
        [self installUpdate:call result:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}


#pragma mark - SuotaManagerDelegate

- (void) onFailure:(int)errorCode {
    NSString *errorMessage = SuotaProfile.suotaErrorCodeList[@(errorCode)];
    self.flutterResult([FlutterError errorWithCode:@"Error updating the device"
                               message:errorMessage
                               details:nil]);
}

- (void) onConnectionStateChange:(enum SuotaManagerStatus)newStatus {
}

- (void) onServicesDiscovered {
}

- (void) onCharacteristicRead:(enum CharacteristicGroup)characteristicGroup characteristic:(CBCharacteristic*)characteristic {
}

- (void) onDeviceInfoReadCompleted:(enum DeviceInfoReadStatus)status {
}

- (void) onDeviceReady {
    NSLog(@"SUOTA Device is ready");
    [self.centralManager stopScan];
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* fullFilePath = [NSString pathWithComponents:@[self.filePath, self.fileName]];
    if (![fileManager fileExistsAtPath:fullFilePath]) {
        NSLog(@"SUOTA File is not OK");
            self.flutterResult([FlutterError errorWithCode:@"DEVICE_NOT_FOUND"
                                       message:@"Device not found"
                                       details:nil]);
    }

    NSLog(@"SUOTA File is OK");
    SuotaFile* suotaFile = [[SuotaFile alloc] initWithAbsoluteFilePath:fullFilePath];
    self.suotaManager.suotaFile = suotaFile;
    NSLog(@"SUOTA File is set");
    [self.suotaManager initializeSuota];
    NSLog(@"SUOTA Suota initiated");
    
//    self.flutterResult(@(YES));
    [self.suotaManager startUpdate];
}

- (void) onSuotaLog:(enum SuotaProtocolState)state type:(enum SuotaLogType)type log:(NSString*)log {
}

- (void) onChunkSend:(int)chunkCount totalChunks:(int)totalChunks chunk:(int)chunk block:(int)block blockChunks:(int)blockChunks totalBlocks:(int)totalBlocks {
}

- (void) updateSpeedStatistics:(double)current max:(double)max min:(double)min avg:(double)avg {}

- (void) onBlockSent:(int)block totalBlocks:(int)totalBlocks {
}

- (void) updateCurrentSpeed:(double)currentSpeed {
}

- (void) onUploadProgress:(float)percent {
    NSDictionary *progressUpdate = @{@"progress": @(percent)};
    self.flutterEventSink(progressUpdate);
}

- (void) onSuccess:(double)totalElapsedSeconds imageUploadElapsedSeconds:(double)imageUploadElapsedSeconds {
    self.flutterResult(@(YES));
}

- (void) onRebootSent {
}

#pragma mark - SuotaManagerDelegate

- (FlutterError * _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    self.flutterEventSink = nil;
    NSLog(@"SUOTA Progress stream listener removed.");
    return nil;
}

- (FlutterError * _Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(nonnull FlutterEventSink)events {
    self.flutterEventSink = events;
    NSLog(@"SUOTA Progress stream listener added.");
    return nil;
}

@end
