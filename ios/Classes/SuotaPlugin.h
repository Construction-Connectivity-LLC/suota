#import <Flutter/Flutter.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "SuotaLib.h"

@interface SuotaPlugin : NSObject<FlutterPlugin, FlutterStreamHandler, CBCentralManagerDelegate, CBPeripheralDelegate, SuotaManagerDelegate>
@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) NSMutableDictionary<NSString *, CBPeripheral *> *discoveredPeripherals;
@property (strong, nonatomic) CBPeripheral *targetPeripheral;
@property (strong, nonatomic) FlutterResult flutterResult;
@property (strong, nonatomic) FlutterEventSink flutterEventSink;
@property (strong, nonatomic) NSString *fileName;
@property (strong, nonatomic) NSString *filePath;
@property (strong, nonatomic) NSString *targetRemoteId;
@property (strong, nonatomic) SuotaManager* suotaManager;
@end
