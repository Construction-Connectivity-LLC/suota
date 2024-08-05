import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'suota_platform_interface.dart';

/// An implementation of [SuotaPlatform] that uses method channels.
class MethodChannelSuota extends SuotaPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('renesas_suota');

  final _eventChannel = const EventChannel('renesas_suota/events');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }


  @override
  Future<bool> installUpdate(String path,
      String fileName,
      String remoteId,
      SuotaProgressCallback? progressCallback,
      SuotaSuccessCallback? successCallback,
      SuotaFailureCallback? failureCallback) async {
    _eventChannel.receiveBroadcastStream().listen((event) {
      if (event is Map<dynamic, dynamic>) {
        print('event: $event');
        final progress = event['progress'];
        if (progress != null) {
          progressCallback?.call(progress);
        }
      }
    }, onError: (error) {
      print(error);
    });
    return await methodChannel.invokeMethod('installUpdate', {
      'path': path,
      'fileName': fileName,
      'remoteId': remoteId,
    });
  }
}
